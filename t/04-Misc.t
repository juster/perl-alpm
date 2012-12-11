# Test miscellanious functions.

use Test::More;
use ALPM;

is(ALPM->vercmp('0.1', '0.2'), -1);
is(ALPM->vercmp('0.10', '0.2'), 1);
is(ALPM->vercmp('0.001', '0.1'), 0); # 0's are skipped
is(ALPM->vercmp('0.100', '0.2'), 1); # 100 > 2

done_testing;
