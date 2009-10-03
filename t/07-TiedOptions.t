#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);

use ALPM;

my %alpm;
tie %alpm, 'ALPM';
#ok( my %alpm = ALPM::Tied->new );
ok( $alpm{root} = '/' );

#use Data::Dumper;
#print STDERR Dumper(\%alpm), "\n";

is( $alpm{root}, ALPM->get_opt('root') );

my %options = ALPM->get_options();
is( scalar keys %alpm, scalar keys %options );

eval { %alpm = () };
ok( $@ =~ /You cannot empty this tied hash/ );

