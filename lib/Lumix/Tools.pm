#! perl

package Lumix::Tools;

use warnings;
use strict;
use sigma;
use Carp;
use LWP::UserAgent;
use XML::Tiny qw( parsefile );

=head1 NAME

Lumix::Tools - Tools for (some) Panasonic Lumix cameras.

=cut

our $VERSION = '0.01';

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

=head1 SYNOPSIS

    use Lumix::Tools;

    my $cam = Lumix::Tools->new( device => '192.168.1.82' );
    if ( $cam->state->{cammode} eq 'play' ) { ... }

=cut

=head1 METHODS

=head2 $cam = new( args )

Instantiates a new CAM object and connects to the camera.

Args:

=over 8

=item noconnect

Do not connect. You'll need to do an explicit connect() call.

=back

=cut

method new (%args) {
    $self = bless {} => (ref($self)||$self);

    $.device = delete($args{device})
      or croak("Missing device argument");
    $.url = "http://" . $.device;

    for ( qw( verbose trace debug test ) ) {
	next unless exists $args{$_};
	$self->{$_} = delete $args{$_};
    }
    .connect() unless $args{noconnect};

    return $self;
}

=head2 $cam->connect

Connects and queries the camera for its state.

Note that if the camera is sleeping, this can take 20-30 seconds.

=cut

method connect {

    # Initial wakeup can take some time...
    $.ua = LWP::UserAgent->new( timeout => 30 );
    .getstate();
}

=head2 $cam->state

Returns the (stored) state.

The state is a hash with keys batt, cammode, version, play, etc..

=cut

method state {
    .getstate() unless $.state;
    return $.state;
}

=head2 $cam->getstate

Refreshes the state and returns it.

The state is a hash with keys batt, cammode, version, play, etc..

=cut

method getstate {
    my $reply = .camrequest("getstate");
    $.state = $reply->{state};
}

=head2 $cam->camrequest( $mode, %args )

Issues a CAM request.

=cut

method camrequest ( $mode, %args ) {

    my $url = $.url . "/cam.cgi?mode=$mode";
    $url .= join( '&', map { "$_=".$args{$_} } keys(%args ) ) if %args;
    warn("CAMrequest url = $url\n") if $.trace;

    my $response = $.ua->get($url);
    croak( $response->status_line ) unless $response->is_success;

    my $res = parsefile( '_TINY_XML_STRING_' . $response->decoded_content );
    my $reply = flatten($res);
    croak( "CAMrequest fail") unless $reply->{camrply};
    $reply = $reply->{camrply};
    croak( "CAMrequest fail: " . $reply->{result} )
      unless $reply->{result} eq 'ok';

    return $reply;
}

# Flatten a simple XML struct.
sub flatten ($r) {
    my $res = {};
    for my $t ( @$r ) {
	return $t->{content} if $t->{type} eq 't';
	croak("Huh") unless $t->{type} eq 'e';
	$res->{ $t->{name} } = flatten( $t->{content} );
    }
    return $res;
}

=head2 $cam->cdsrequest( $soap )

Issues a CDS (SOAP) request.

Returns the result.

=cut

method cdsrequest ($soap) {

    my $url = $.url . ":60606/Server0/CDS_control";
    warn("CDSrequest url = $url\n") if $.trace;

    my $response =
      $.ua->post( $url,
		  SOAPAction => '"urn:schemas-upnp-org:service:ContentDirectory:1#Browse"',
		  'Content-Type' => 'text/xml; charset="UTF-8"',
		  Content => $soap );

    croak( $response->status_line ) unless $response->is_success;
    return $response->decoded_content;
}

=head2 $cam->browsedirectchildren( $start )

Returns a list of items (pictures, videos) on the camera.

Is $start is provided, the query will start at this item.

Returns an array reference where each element is a hash with the
following keys:

=over 8

=item id

The internal id of the image. Something like C<01000077>.

=item title

The internal name of the image. Something like C<100-0077>.

=item file

The file name compliant with the image name if the SDcard were mounted
on a local file system. Something like C<pana0077.jpg>.

=item path

The path for the file, something like C<dcim/100_pana>.

=back

NOTE: The prefixes for path and file are currently fixed.

=cut

method browsedirectchildren ($start) {

    my $count = 50;
    $start ||= 0;
    my $have = $start + 1;

    my @res;

    while ( $start < $have ) {
	warn("BrowseDirectChildren: Fetching from $start...\n") if $.verbose;

	my $res = .cdsrequest( <<EOD );
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:Browse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">
<ObjectID>0</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter></Filter>
<StartingIndex>$start</StartingIndex>
<RequestedCount>$count</RequestedCount>
<SortCriteria></SortCriteria>
</u:Browse>
</s:Body>
</s:Envelope>
EOD

	# Yes, I know it is wrong to attack XML with regexps...
	$have = $1 if $res =~ m;<TotalMatches>(\d+)</TotalMatches>;;
	my $got  = $1 if $res =~ m;<NumberReturned>(\d+)</NumberReturned>;;
        croak("BrowseDirectChildren: Nothing?") unless $got;
	warn("BrowseDirectChildren: Got $got of $have\n") if $.verbose;

	croak("BrowseDirectChildren: No results?")
	  unless $res =~ m;<Result>(.*?)</Result>;;
	my $data = $1;
	$data =~ s/&quot;/'/g;
	$data =~ s/&lt;/</g;
	$data =~ s/&gt;/>/g;

	while ( $data =~ m;<item\s+id='(.+?)'.*?>(.+?)</item>;g ) {
	    my $item  = $2;
	    my $id    = $1;
	    my $title = $1 if $item =~ m;<dc:title>(.+?)</dc:title>;;
	    my $class = $1 if $item =~ m;<upnp:class>(.+?)</upnp:class>;;
	    my ( $dcim, $seq ) = $id =~ /^(\d\d\d\d)(\d\d\d\d)$/;

	    # Make compliant file names.
	    my $file;
	    my $ext;
	    if ( $class eq 'object.item.imageItem' ) {
		$ext = "jpg";
		$file = sprintf( 'pana%04d.%s', $seq, $ext );
	    }
	    elsif ( $class eq 'object.item.videoItem.movie' ) {
		$ext = "mp4";
		$file = sprintf( 'pana%04d.%s', $seq, $ext );
	    }

	    unless ( $file ) {
		warn("BrowseDirectChildren: Ignored $id ($class)\n");
		next;
	    }

	    push( @res, { id   => $id,   title => $title, file  => $file,
			  path => sprintf( "dcim/%03d_pana", $dcim ),
			  ext  => $ext,  class => $class,
			} );
	}

	$start += $got;
    }

    return \@res;
}

=head2 $cam->getimage( $item )

Fetches the content of an item and returns it.

C<$item> must be an element of the result set of a call to
browsedirectchildren.

WARNING: This is an in-core transfer, so it is probably not a good
idea to use this for fetching multi-gigabyte movies...

=cut

method getimage ( $item ) {
    my $url = $.url . ":50001/DO$item->{id}.$item->{ext}";
    warn("GetImage: url = $url\n") if $.trace;

    my $response = $.ua->get($url);
    croak( $response->status_line ) unless $response->is_success;

    return $response->decoded_content;
}

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Lumix-Tools.

You can find documentation for this module with the perldoc command.

    perldoc Lumix::Tools

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2021 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lumix::Tools
