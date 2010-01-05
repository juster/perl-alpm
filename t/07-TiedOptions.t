#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 6;

use ALPM;

my %alpm;
tie %alpm, 'ALPM';
ok( $alpm{root} = '/' );

is( $alpm{root}, ALPM->get_opt('root') );

my %options = ALPM->get_options();
is( scalar keys %alpm, scalar keys %options );

eval { %alpm = () };
ok( $@ =~ /You cannot empty this tied hash/ );

{
    my $warn_str = q{};
    local $SIG{__WARN__} = sub { $warn_str = $_[0] };

    eval { delete $alpm{root} };
    like( $warn_str, qr/^Use of uninitialized value in subroutine entry at/,
          'a warning is given for passing alpm_option_set_root the arg undef' );
    ok( $@, q{cannot delete a string option's tied hash key} );
}

