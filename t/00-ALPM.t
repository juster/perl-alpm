#!/usr/bin/perl
##
# Initialize ALPM then set and check a few options.
# Checks add/remove on what we can.

use Test::More;

$ENV{'LANGUAGE'} = 'en_US';

BEGIN { use_ok('ALPM') };

$r = 't/root';
$alpm = ALPM->new($r, "$r/db");
ok $alpm;

ok $alpm->version; # just checks it works
@caps = $alpm->caps;

%opts = (
	'arch' => 'i686',
	'logfile' => "$r/log",
	'gpgdir' => "$r/gnupg",
	'cachedirs' => [ "$r/cache/" ], # needs trailing slash
	'noupgrades' => [ 'foo' ],
	'noextracts' => [ 'bar' ],
	'ignorepkgs' => [ 'baz' ],
	'ignoregroups' => [ 'core' ],
	'usesyslog' => 0,
	'usedelta' => 0,
	'checkspace' => 1,
);

sub meth
{
	my $name = shift;
	my $m = *{"ALPM::$name"}{CODE} or die "missing $name method";
	my $ret = eval { $m->($alpm, @_) };
	if($@){ die "method call to $name failed: $@" }
	return $ret;
}

for $k (sort keys %opts){
	$v = $opts{$k};
	@v = (ref $v ? @$v : $v);
	ok meth("set_$k", @v), "set_$k successful";

	@x = meth("get_$k");
	is $#x, $#v, "get_$k returns same size list as set_$k";
	for $i (0 .. $#v){
		is $x[$i], $v[$i], "get_$k has same value as set_$k args";
	}

	next unless($k =~ s/s$//);
	is meth("remove_$k", $v[0]), 1, "remove_$k reported success";
	ok scalar meth("get_${k}s") == (@v - 1), "$v[0] removed from ${k}s";
}

# TODO: Test SigLevels more in a later test.
is $alpm->get_default_siglevel, 'never';
ok $alpm->set_default_siglevel('default');

if(grep { /signatures/ } @caps){
	is $alpm->get_default_siglevel, 'default';
	ok $alpm->set_default_siglevel({ 'pkg' => ['never'], 'db' => ['required'] });
	$siglvl = $alpm->get_default_siglevel;
	is $siglvl->{'pkg'}[0], 'never';
	is $isglvl->{'db'}[0], 'required';
}else{
	is $alpm->get_default_siglevel, 'never';
	$siglvl = { 'pkg' => ['never'], 'db' => ['required'] };
	eval { $alpm->set_default_siglevel($siglvl); };
	if($@ =~ /^ALPM Error: wrong or NULL argument passed/){
		pass q{can set siglevel to "default" or "never" without GPGME};
	}else{
		fail 'should not be able to set complicated siglevel without GPGME';
	}
}

done_testing;
