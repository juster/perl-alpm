#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 5;

use Data::Dumper;

use ALPM; # qw(t/test.conf);
use Cwd;
use File::Find;
use File::Copy;
use File::Path;
use File::Spec::Functions qw(rel2abs);

my $REPOS_BUILD = rel2abs('t/repos/build');
my $REPOS_SHARE = rel2abs('t/repos/share');
my $TEST_ROOT   = rel2abs('t/root');

my $start_dir = cwd();

sub create_conf
{
    chdir $start_dir;
    open my $conf_file, '>', 't/test.conf'
        or die "failed to open t/test.conf file: $!";

    print $conf_file <<"END_CONF";
[options]
RootDir  = $TEST_ROOT
DBPath   = $TEST_ROOT/db/
CacheDir = $TEST_ROOT/cache/
LogFile  = $TEST_ROOT/test.log

END_CONF

#     for my $repo ( @repos ) {
#         print $conf_file <<"END_REPO";
# [$repo]
# Server   = file://$REPOS_SHARE/$repo

# END_REPO
#     }

    close $conf_file;
}

sub create_adder
{
    my ($repo_name) = @_;

    my $reposhare = "$REPOS_SHARE/$repo_name";

    return sub {
        return unless /[.]pkg[.]tar[.]gz$/;
        system 'repo-add', "$reposhare/$repo_name.db.tar.gz",
            $File::Find::name
                and die "error $? with repo-add in $REPOS_SHARE";
        copy( $_, "$reposhare/$_" );
    }
}

sub create_repos
{
    opendir BUILDDIR, $REPOS_BUILD
        or die "couldn't opendir on $REPOS_BUILD: $!";

    chdir $REPOS_BUILD;
    my @repos = grep { !/[.]{1,2}/ && -d $_ } readdir BUILDDIR;
    for my $repodir ( @repos ) {
        opendir REPODIR, "$REPOS_BUILD/$repodir"
            or die "couldn't opendir on $REPOS_BUILD/$repodir";
        chdir "$REPOS_BUILD/$repodir";
        for my $pkgdir ( grep { !/[.]{1,2}/ && -d $_ } readdir REPODIR ) {
            chdir "$REPOS_BUILD/$repodir/$pkgdir";
            system 'makepkg -fd >/dev/null 2>&1'
                and die "error for makepkg in $pkgdir: $?";
        }
        closedir REPODIR;

        mkpath( "$REPOS_SHARE/$repodir" );
        find( create_adder( $repodir ), "$REPOS_BUILD/$repodir" );
    }

    return @repos;
}

# Don't need this since I got DB::update() to work.
# (use absolute paths for everything)
sub copy_sync_db
{
    chdir $start_dir;
    mkpath( "$TEST_ROOT/db/sync/simpletest" )
        or die "mkpath for simpltest db failed: $!";
    system 'tar', ( '-zxf' => "$REPOS_SHARE/simpletest.db.tar.gz",
                    '-C'   => "$TEST_ROOT/db/sync/simpletest/" )
        and die "error $? when untarring db tarball failed";
}

sub clean_root
{
    die "WTF?" if $TEST_ROOT eq '/';

    rmtree( $TEST_ROOT );
    mkpath( "$TEST_ROOT/db/local", "$TEST_ROOT/db/sync",
            "$TEST_ROOT/cache", );
    return 1;
}

sub corrupt_package
{
    my $arch = `uname -m`;
    chomp $arch;

    my $fqp = rel2abs( "$REPOS_SHARE" )
        . "/simpletest/corruptme-1.0-1-$arch.pkg.tar.gz";

    unlink $fqp or die "failed to unlink file whilst corrupting: $!";

    open my $pkg_file, '>', $fqp
        or die "failed to open file whilst corrupting: $!";
    print $pkg_file "HAHA PWNED!\n";
    close $pkg_file;

    return;
}

SKIP:
{
    skip 'test repositories are already created', 1
        if ( -e "$REPOS_SHARE" );
    diag( "creating test repositories" );
    my @repos = create_repos();
    ok( @repos, 'create test package repository' );

    diag( "created @repos test repositories" );

    corrupt_package();
}

create_conf();

diag( "initializing our test rootdir" );
ok( clean_root(), 'remake fake root dir' );

ok( ALPM->load_config( 't/test.conf' ), 'load our generated config' );
#ALPM->set_opt( 'logcb', sub { printf STDERR '[%10s] %s', @_; } );

for my $reponame ( 'simpletest', 'upgradetest' ) {
    ok( my $db = ALPM->register_db( $reponame,
                           sprintf( 'file://%s/%s', rel2abs( $REPOS_SHARE ),
                                    $reponame )) );
    $db->update;
}


