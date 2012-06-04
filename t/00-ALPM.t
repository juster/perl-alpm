#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 2;
use English (-no_match_vars);
BEGIN { use_ok('ALPM') };

$ENV{'LANGUAGE'} = 'en_US';

my $alpm = ALPM->new('t/root', 't/root/db');
ok($alpm);
