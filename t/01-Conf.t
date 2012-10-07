use Test::More;

use_ok 'ALPM';
use_ok 'ALPM::Conf';

$conf = ALPM::Conf->new('t/test.conf');
ok $alpm = $conf->parse_options();

done_testing;
