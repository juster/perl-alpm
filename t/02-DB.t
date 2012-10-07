use Test::More;

use ALPM::Conf 't/test.conf';
ok $alpm;

sub checkpkgs
{
	my $db = shift;
	my $dbname = $db->name;
	my %set = map { ($_ => 1) } @_;
	for my $p ($db->pkgs){
		my $n = $p->name;
		unless(exists $set{$n}){
			fail "unexpected $n package exists in $dbname";
			return;
		}
		delete $set{$n};
	}
	if(keys %set){
		fail "missing packages in $dbname: " . join q{ }, keys %set;
	}
	pass "all expected packages exist in $dbname";
}

use Devel::Peek;

$db = $alpm->localdb;
is $db->name, 'local';

@dbs = $alpm->syncdbs;
for $d (@dbs){
	print STDERR "DBG: ", $d->name, "\n";
	for $p ($d->pkgs){
		print STDERR "DBG: %s\t%s\n", $d->name, $p->name;
	}
}

$db = $alpm->db('simpletest');
$db->_update(1);
for $p ($db->pkgs){
	print STDERR "DBG: %s\t%s\n", $d->name, $p->name;
}
checkpkgs($db, qw/foo bar/);

done_testing;
