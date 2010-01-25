#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 5;

use Data::Dumper;

use ALPM;
use Cwd;
use English qw( -no_match_vars );
use File::Find;
use File::Copy;
use File::Path qw( make_path remove_tree );
use File::Spec::Functions qw( rel2abs );

my $REPOS_BUILD = rel2abs('t/repos/build');
my $REPOS_SHARE = rel2abs('t/repos/share');
my $TEST_ROOT   = rel2abs('t/root');
my $TEST_CONF   = 't/test.conf';

my $start_dir = cwd();

sub create_conf
{
    my $conf_path = shift;

    chdir $start_dir;
    open my $conf_file, '>', $conf_path
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
    my $reposhare   = "$REPOS_SHARE/$repo_name";

    return sub {
        return unless /[.]pkg[.]tar[.]gz$/;
        system 'repo-add', "$reposhare/$repo_name.db.tar.gz", $File::Find::name
                and die "error ", $? >> 8, " with repo-add in $REPOS_SHARE";
        rename $_, "$reposhare/$_";
    }
}

sub create_repos
{
    opendir BUILDDIR, $REPOS_BUILD
        or die "couldn't opendir on $REPOS_BUILD: $!";

    my $makepkg_opts = join q{ }, qw/ -f -d -c /,
      ( $EFFECTIVE_USER_ID == 0 ? '--asroot' : qw// );

    chdir $REPOS_BUILD;
    my @repos = grep { !/[.]{1,2}/ && -d $_ } readdir BUILDDIR;
    # Loop through each repository's build directory...
    for my $repodir ( @repos ) {
        opendir REPODIR, "$REPOS_BUILD/$repodir"
            or die "couldn't opendir on $REPOS_BUILD/$repodir";
        chdir "$REPOS_BUILD/$repodir"
            or die qq{cannot chdir to repodir "$repodir"};

	# Create each package, which is a PKGBUILD in a each subdir...
        for my $pkgdir ( grep { !/[.]{1,2}/ && -d $_ } readdir REPODIR ) {
            chdir "$REPOS_BUILD/$repodir/$pkgdir"
                or die qq{cannot chdir to pkgdir "$pkgdir"};

            system "makepkg $makepkg_opts >/dev/null 2>&1"
                and die 'error code ', $? >> 8, ' from makepkg in $pkgdir: ';
        }
        closedir REPODIR;

	# Move each repo's package to the share dir and add it to the
	# repo's db.tar.gz file...
        make_path( "$REPOS_SHARE/$repodir", { mode => 0755 } );
        find( create_adder( $repodir ), "$REPOS_BUILD/$repodir" );
    }

    return @repos;
}

sub clean_root
{
    die "WTF?" if $TEST_ROOT eq '/';

    remove_tree( $TEST_ROOT, { keep_root => 1 } );
    make_path( "$TEST_ROOT/db/local", "$TEST_ROOT/db/sync",
	       "$TEST_ROOT/cache", { mode => 0755 } );
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

    @repos = map { qq{'$_'} } @repos;
    my $repos_list = join q{ and },
      ( join q{, }, @repos[0 .. $#repos-1] ), $repos[-1];

    diag( "created $repos_list repos" );

    corrupt_package();
}

# Allows me to tweak the test.conf file and not have it overwritten...
create_conf( $TEST_CONF ) unless ( -e $TEST_CONF );

diag( "initializing our test rootdir" );
ok( clean_root(), 'remake fake root dir' );

ok( ALPM->load_config( $TEST_CONF ), 'load our generated config' );
#ALPM->set_opt( 'logcb', sub { printf STDERR '[%10s] %s', @_; } );

for my $reponame ( 'simpletest', 'upgradetest' ) {
    ok( my $db = ALPM->register_db( $reponame,
                           sprintf( 'file://%s/%s', rel2abs( $REPOS_SHARE ),
                                    $reponame )) );
    $db->update;
}


