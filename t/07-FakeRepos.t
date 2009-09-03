#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

use Data::Dumper;

use ALPM qw(t/fakeroot/etc/pacman.conf);

ok( my $db = ALPM->repodb('simpletest') );
is( $db->name, 'simpletest' );



