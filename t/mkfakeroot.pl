#!/usr/bin/env perl
use warnings;
use strict;

use Cwd;
use English qw(-no_match_vars);
use File::Find;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Spec::Functions qw(rel2abs catfile);

my $PROG = 'mkfakeroot';
my $REPOS_BUILD = rel2abs('t/repos/build');
my $REPOS_SHARE = rel2abs('t/repos/share');
my $TEST_ROOT   = rel2abs('t/root');
my $TEST_CONF   = 't/test.conf';
my $PKGEXT;

sub confpkgext
{

	return '.pkg.tar.xz' unless(-f '/etc/makepkg.conf');
	my $bash = q{source /etc/makepkg.conf; echo $PKGEXT};

	# Make sure we are reading the last line.
	my($pkgext) = reverse qx{bash -c '$bash'};
	chomp $pkgext;
	
	die 'failed to read PKGEXT from /etc/makepkg.conf' unless($pkgext);
	return $pkgext;
}

sub create_conf
{
	my $conf_path = shift;

	open my $conf_file, '>', $conf_path
		or die "failed to open t/test.conf file: $!";

	print $conf_file <<"END_CONF";
[options]
RootDir  = $TEST_ROOT
DBPath   = $TEST_ROOT/db/
CacheDir = $TEST_ROOT/cache/
LogFile  = $TEST_ROOT/test.log

END_CONF

	close $conf_file;
}

sub create_adder
{
    my ($repo_name) = @_;
	my $reposhare   = "$REPOS_SHARE/$repo_name";
	my $ext         = quotemeta $PKGEXT;

	return sub {
		return unless /${ext}$/;
		system 'repo-add', "$reposhare/$repo_name.db.tar.gz", $File::Find::name
			and die "error ", $? >> 8, " with repo-add in $REPOS_SHARE";
		rename $_, "$reposhare/$_";
	}
}

sub create_repos
{
	opendir BUILDDIR, $REPOS_BUILD
		or die "couldn't opendir on $REPOS_BUILD: $!";

	my $opts = join q{ }, qw/-f -d -c/,
		($EFFECTIVE_USER_ID == 0 ? '--asroot' : qw//);

	chdir $REPOS_BUILD or die "chdir $REPOS_BUILD: $!";
	my @repos = grep { !/^[.]/ && -d $_ } readdir BUILDDIR;

	# Loop through each repository's build directory...
	for my $repodir (@repos){
		opendir REPODIR, "$REPOS_BUILD/$repodir"
			or die "opendir $REPOS_BUILD/$repodir: $!";

		# Create each package, made from a PKGBUILD in each subdir...
		for my $pkgdir (grep { !/[.]{1,2}/ && -d $_ } readdir REPODIR){
			chdir "$REPOS_BUILD/$repodir/$pkgdir"
				or die qq{chdir to pkgdir: $pkgdir: $!};

			system "makepkg $opts >/dev/null 2>&1";
			die 'error code ', $? >> 8, ' from makepkg in $pkgdir' if($? != 0);
		}
		closedir REPODIR;

		# Move each repo's package to the share dir and add it to the
		# repo's db.tar.gz file...
		make_path("$REPOS_SHARE/$repodir", { mode => 0755 });
		find(create_adder($repodir), "$REPOS_BUILD/$repodir");
	}

	return @repos;
}

sub clean_root
{
	die "WTF?" if $TEST_ROOT eq '/';

	remove_tree($TEST_ROOT, { keep_root => 1 });
	make_path("$TEST_ROOT/db/local",
		"$TEST_ROOT/db/sync",
		"$TEST_ROOT/cache", { mode => 0755 });
	return 1;
}

sub corrupt_package
{
	my ($fqp) = catfile(rel2abs($REPOS_SHARE),
		q{simpletest},
		qq{corruptme-1.0-1-any$PKGEXT});

	unlink $fqp or die "failed to unlink file whilst corrupting: $!";

	open my $pkg_file, '>', $fqp or die "failed to open file whilst corrupting: $!";
	print $pkg_file "HAHA PWNED!\n";
	close $pkg_file or die "close: $!";

	return;
}

if(-e $REPOS_SHARE){
	print STDERR "$PROG: test repositories are already created\n";
}else{
	$PKGEXT = confpkgext();
	print STDERR "$PROG: creating test repos...\n";
	chdir 'repos' or die "chdir repos: $!";
	my @pkgfiles = `./build.pl`;
	if($? != 0){
		printf STDERR "$PROG: t/repos/build.pl failed", $? >> 8;
		exit $? >> 8;
	}
	print for(@pkgfiles);
	exit 0;
	corrupt_package();
}

# Allows me to tweak the test.conf file and not have it overwritten...
create_conf($TEST_CONF) unless(-e $TEST_CONF);

print STDERR "initializing our test rootdir...\n";
print STDERR (clean_root() ? "failed!\n" : "success.\n");
