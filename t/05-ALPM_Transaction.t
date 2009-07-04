#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

use ALPM qw(t/fake/etc/pacman.conf);

ok( ALPM->transaction( type => 'sync' ) );
