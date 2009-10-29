#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 5;

use ALPM;

my %alpm;
tie %alpm, 'ALPM';
ok( $alpm{root} = '/' );

is( $alpm{root}, ALPM->get_opt('root') );

my %options = ALPM->get_options();
is( scalar keys %alpm, scalar keys %options );

eval { %alpm = () };
ok( $@ =~ /You cannot empty this tied hash/ );

diag 'A warning should show about an unitialized value';
eval { delete $alpm{root} };
ok( $@, q{cannot delete a string option's tied hash key} );

