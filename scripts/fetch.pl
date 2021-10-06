#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Sat Jul  3 20:48:13 2021
# Last Modified By: Johan Vromans
# Last Modified On: Wed Oct  6 13:15:21 2021
# Update Count    : 119
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Package name.
my $my_package = 'Lumix';
# Program name and version.
my ($my_name, $my_version) = qw( fetch 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $device = "tz200.squirrel.nl";
my $start = 0;
my $count = 50;
my $path;			# path override
my @excludes;
my $verbose = 1;		# verbose processing
my $poweroff = 0;		# poweroff upon completion

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $pid = $test || $$;
my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use Lumix::Tools;
use List::Util qw( any );

my $have = $start + 1;		# get going

my $cam = Lumix::Tools->new( device  => $device,
			     verbose => $verbose,
			     trace   => $trace,
			     debug   => $debug,
			   );

my $list = $cam->browsedirectchildren($start);

my $fetched = 0;

for my $item ( @$list ) {
    my $path = $path // $item->{path};
    my $file = $path . "/" . $item->{file};
    warn(sprintf("%s %-10s %s\n", $item->{id}, $item->{title}, $file ))
      if $trace;

    if ( any { $_ eq $item->{file} } @excludes ) {
	warn("Exclude: $file\n") if $verbose;
	next;
    }

    if ( -s $file ) {
	warn("Exists: $file\n") if $verbose > 1;
	next;
    }

    open( my $fd, '>:raw', $file ) or die("$file: $!\n");
    print $fd $cam->getimage($item);
    close($fd) or die("$file: $!\n");
    $fetched++;
    warn("Fetched: $file (", -s $file, " bytes)\n") if $verbose;

}

if ( ($poweroff > 1) ? 1 : $fetched ) {
    warn("Powering off...\n") if $verbose;
    $cam->poweroff;
}

exit 0;

################ Subroutines ################

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions( 'device=s'  => \$device,
		    'start=i'   => \$start,
		    'count=i'   => \$count,
		    'path=s'    => \$path,
		    'exclude=s@' => \@excludes,
		    'poweroff+'	=> \$poweroff,
		    'ident'	=> \$ident,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'test'	=> \$test,
		    'help|?'	=> \$help,
		    'man'	=> \$man,
		    'debug'	=> \$debug )
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

__END__

################ Documentation ################

=head1 NAME

fetch - Fetch images from WiFi connected Panasonic Lumix

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   --device=XXX		the device to use
   --start=NN		start at image index NN
   --count=NN		fetch max. NN images
   --path=XXX		path for images
   --exclude=XXX	exclude these images (multiple)
   --poweroff		poweroff after fetching (multiple)
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--device=>I<XXX>

The host name of the camera. The default is useful for me, probably
not for you.

=item B<--start=>I<NN>

Start image fetching with image number NN (default: 0, first image).

=item B<--count=>I<NN>

Fetch at most NN images.

=item B<--path=>I<XXX>

The destination for the fetched images,

=item B<--exclude=>I<XXX>

Do not download these images. Useful if you have a persistent image
(e.g. pana0001.jpg) with owner information that you don't want to be
fetched.

=item B<--poweroff>

Power off the camera when images have been fetched,

Specify twice to power off the camera even when no images have been
fetched.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=item I<file>

The input file(s) to process, if any.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do someting
useful with the contents thereof.

=cut
