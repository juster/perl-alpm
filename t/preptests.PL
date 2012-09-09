#!/usr/bin/env perl
use warnings;
use strict;

use Cwd;
use English qw(-no_match_vars);
use File::Find;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Spec::Functions qw(rel2abs catfile);

my $PROG = 'preptests';
my $REPOS_SHARE = rel2abs('repos/share');
my $TEST_ROOT = rel2abs('root');
my $TEST_CONF = 'test.conf';
my $PKGEXT;

sub createconf
{
	my($path, $root) = @_;
	open my $of, '>', $path
		or die "failed to open t/test.conf file: $!";
	print $of <<"END_CONF";
[options]
RootDir = $root
DBPath = $root/db
CacheDir = $root/cache
LogFile = $root/test.log
END_CONF
	close $of;
}

sub buildpkgs
{
	chdir 'repos' or die "chdir: $!";
	my @lines = `perl package.pl`;
	chdir '..' or die "chdir: $!";

	if(@?){
		printf STDERR "$PROG: package.pl script failed: code %d\n", $? >> 8;
		exit 1;
	}

	my %repos;
	for (@lines){
		chomp;
		my($r, @rest) = split /\t/;
		push @{$repos{$r}}, join "\t", @rest;
	}

	return \%repos;
}

sub remkdir
{
	my($dir) = @_;
	die "WTF?" if($dir eq '/');
	remove_tree($dir);
	mkdir($dir);
	return;
}

sub mkroot
{
	remkdir($TEST_ROOT);
	make_path("$TEST_ROOT/db/local",
		"$TEST_ROOT/db/sync",
		"$TEST_ROOT/cache", { mode => 0755 });
}

sub corruptpkg
{
	my $fqp = "$REPOS_SHARE/simpletest/corruptme-1.0-1-any.pkg.tar.xz";
	unlink $fqp or die "unlink: $!";

	open my $fh, '>', $fqp or die "open: $!";
	print $fh "HAHA PWNED!\n";
	close $fh or die "close: $!";

	return;
}

if(-e $REPOS_SHARE){
	print STDERR "$PROG: Warning: test repositories are already created!\n";
}else{
	my $repos = buildpkgs();
	chdir 'repos' or die "chdir: $!";

	mkdir $REPOS_SHARE or die "mkdir: $!";
	for my $r (sort keys %$repos){
		my $rd = "$REPOS_SHARE/$r";
		mkdir $rd or die "mkdir: $!";
		mkdir "$rd/contents" or die "mkdir: $!";

		for my $pkg (@{$repos->{$r}}){
			system 'perl' => 'repoadd.pl', $rd, $pkg;
			if($?){
				print STDERR "$PROG: repoadd.pl failed\n";
				exit 1;
			}
		}

		system 'perl' => 'repofin.pl', $rd;
		if($?){
			print STDERR "$PROG: repofin.pl failed\n";
			exit 1;
		}
	}
	chdir '..' or die "chdir: $!";

	#corruptpkg();
}

# MakeMaker passes our path name (sans .PL) as an argument.
if(@ARGV){
	chdir(dirname(shift)) or die "chdir: $!";
}

# Allows me to tweak the test.conf file and not have it overwritten...
createconf($TEST_CONF) unless(-e $TEST_CONF);
mkroot();
