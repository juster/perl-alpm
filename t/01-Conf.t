use Test::More;

use_ok 'ALPM::Conf';
$conf = ALPM::Conf->new('t/test.conf');
ok $alpm = $conf->parse();

undef $alpm;

ALPM::Conf->import('t/test.conf');
ok $alpm;
is $alpm->get_arch, 'auto';

done_testing;
