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
	}else{
		pass "all expected packages exist in $dbname";
	}
}

sub checkdb
{
	my $dbname = shift;
	my $db = $alpm->db($dbname);
	is $db->name, $dbname, 'dbname matches db() arg';
	checkpkgs($db, @_);
}

$db = $alpm->localdb;
is $db->name, 'local';

## Make sure DBs are synced.
$_->update or die $alpm->errstr for($alpm->syncdbs);

checkdb('simpletest', qw/foo bar/);
checkdb('upgradetest', qw/foo replacebaz/);

done_testing;
