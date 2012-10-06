use Test::More;

use_ok 'ALPM';
use_ok 'ALPM::Conf';

$conf = ALPM::Conf->new('t/test.conf');
$alpm = ALPM->new('t/root', 't/root/db');
$conf->parse_options($alpm);

done_testing;
