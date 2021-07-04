#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lumix::Tools' );
}

diag( "Testing Lumix::Tools $Lumix::Tools::VERSION, Perl $], $^X" );
