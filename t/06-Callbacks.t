use Test::More;
use ALPM::Conf 't/test.conf';
use Scalar::Util qw(reftype refaddr);

ok !defined $alpm->get_logcb;
$cb = sub { print "LOG: @_" };
die 'internal error' unless(reftype($cb) eq 'CODE');
$alpm->set_logcb($cb);

$tmp = $alpm->get_logcb($cb);
is reftype($tmp), 'CODE';
ok refaddr($tmp) == refaddr($cb);

$alpm->set_logcb(undef);
ok !defined $alpm->get_logcb;

done_testing;
