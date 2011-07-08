#!/usr/bin/perl
##
# Test miscellanious functions.

use warnings;
use strict;
use Test::More;

use ALPM ('root' => '/',
          'dbpath' => '/var/lib/pacman');

is(ALPM->vercmp('0.1', '0.2'), -1);
is(ALPM->vercmp('0.10', '0.2'), 1);
is(ALPM->vercmp('0.001', '0.1'), 0); # 0's are skipped
is(ALPM->vercmp('0.100', '0.2'), 1); # 100 > 2

done_testing;
