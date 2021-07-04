#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Sat Jul  3 20:48:13 2021
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jul  4 14:16:43 2021
# Update Count    : 99
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'Lumix';
# Program name and version.
my ($my_name, $my_version) = qw( fetch 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $device = "tz200.squirrel.nl";
my $start = 0;
my $count = 50;
my $verbose = 1;		# verbose processing

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

my $have = $start + 1;		# get going

my $cam = Lumix::Tools->new( device  => $device,
			     verbose => $verbose,
			     trace   => $trace,
			     debug   => $debug,
			   );

my $list = $cam->browsedirectchildren($start);

for my $item ( @$list ) {

    my $file = $item->{path} . "/" . $item->{file};
    warn(sprintf("%s %-10s %s\n", $item->{id}, $item->{title}, $file ))
      if $trace;

    next if -s $file;

    open( my $fd, '>:raw', $file ) or die("$file: $!\n");
    print $fd $cam->getimage($item);
    close($fd) or die("$file: $!\n");
    warn("Fetched: $file (", -s $file, " bytes)\n") if $verbose;

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

sample - skeleton for GetOpt::Long and Pod::Usage

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

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
