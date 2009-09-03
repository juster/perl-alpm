#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;
use English (-no_match_vars);
BEGIN { use_ok('ALPM') };

my $fail   = eval { ALPM::initialize() };
my $errmsg = $EVAL_ERROR;
is( $fail, undef );
like( $errmsg, qr/^ALPM Error: library already initialized/,
      'automatic initializes' );
