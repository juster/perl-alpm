#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

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
#EOF

END_CONF
    close $conf_file;
}

sub find_and_add
{
    return unless /[.]pkg[.]tar[.]gz$/;
    system 'repo-add', "$REPOS_SHARE/simpletest.db.tar.gz", $File::Find::name
        and die "error $? with repo-add in $REPOS_SHARE";
    copy( $_, "$REPOS_SHARE/$_" );
}

sub create_repos
{
    chdir $start_dir;
    opendir BUILDDIR, $REPOS_BUILD
        or die "couldn't opendir on $REPOS_BUILD: $!";

    chdir $REPOS_BUILD;
    for my $pkgdir ( grep { !/[.]{1,2}/ && -d } readdir BUILDDIR ) {
        chdir $pkgdir;
        system 'makepkg -fR >/dev/null 2>&1'
            and die "error for makepkg in $pkgdir: $?";
        chdir '..';
    }

    rmtree( $REPOS_SHARE, { keep_root => 1 } );
    find( \&find_and_add, $REPOS_BUILD );

    return 1;
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

diag( "initializing our test rootdir" );
ok( clean_root(), 'remake fake root dir' );

diag( "creating test repository" );
ok( create_repos(), 'create test package repository' );

create_conf();
ok( ALPM->load_config( 't/test.conf' ), 'load our generated config' );
ALPM->set_opt( 'logcb', sub { printf STDERR '[%10s] %s', @_; } );
ok( my $db = ALPM->register_db( 'simpletest',
                                'file://' . rel2abs( $REPOS_SHARE )) );
is( $db->name, 'simpletest' );
ok( $db->update );



