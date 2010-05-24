package App::PerlPacman::Query;
use base qw(App::PerlPacman);

use warnings;
use strict;

use ALPM;

sub option_spec
{
    qw{ changelog deps explicit groups info check|k list foreign|m 
        owns:s file|p:s search:s unrequired|t upgrades|u quiet|q
        config:s logfile:s noconfirm noprogressbar noscriplet
        verbose debug root dbpath|b cachedir };
}

sub run_opts
{
    my ($class, $packages_ref, %opts) = @_;

    # Loop over all our local db packages if none were specified...
    unless ( @$packages_ref ) {
        $packages_ref = [ ALPM->localdb->packages ];
    }

    $class->filter_packages( $packages_ref, %opts );

    printf "%s %s\n", $_->name, $_->version
        foreach @$packages_ref;

    return 0;
}

sub filter_packages
{
    my ($class, $packages_ref, %opts) = @_;

    my $filters_ref = $class->_create_filters( %opts );
    $class->_filtration( $filters_ref, $packages_ref );

    # Not necessary, because we alter reference in place...
    return $packages_ref;
}

sub _filtration
{
    my ($class, $filters_ref, $packages_ref) = @_;

    FILTER:
    for my $filter ( @$filters_ref ) {
        @$packages_ref = grep { $filter->() } @$packages_ref;
        # Stop if our array is now empty...
        last FILTER unless scalar @$packages_ref;
    }

    return;
}


sub _filter_foreign
{
    our @SyncDBs;
    @SyncDBs = ALPM->syncdbs unless @SyncDBs;

    for my $db ( @SyncDBs ) {
        return 0 if $db->find( $_->name );
    }

    return 1;
}

sub _filter_upgrades
{
    our @SyncDBs;
    @SyncDBs = ALPM->syncdbs unless @SyncDBs;

    DB_LOOP:
    for my $db ( @SyncDBs ) {
        my $pkg = $db->find( $_->name ) or next DB_LOOP;

        return 1 if 1 == ALPM::Package::vercmp( $pkg->version, $_->version );
    }
    
    return 0;
}

sub _create_filters
{
    my ($class, %opts) = @_;

    my @filters;
    my $filter = sub {
        my ($optname, $filter_ref) = @_;
        return unless $opts{ $optname };
        push @filters, $filter_ref;
    };

    $filter->( 'deps'       => sub { $_->reason eq 'implicit' } );
    $filter->( 'explicit'   => sub { $_->reason eq 'explicit' } );
    $filter->( 'foreign'    => \&_filter_foreign );
    $filter->( 'unrequired' => sub { 0 == @{ $_->compute_requiredby } } );
    $filter->( 'upgrades'   => \&_filter_upgrades );

    return \@filters;
}

sub help
{
    return <<'END_HELP';
usage:  ppacman {-Q --query} [options] [package(s)]
options:
  -c, --changelog      view the changelog of a package
  -d, --deps           list packages installed as dependencies [filter]
  -e, --explicit       list packages explicitly installed [filter]
  -g, --groups         view all members of a package group
  -i, --info           view package information (-ii for backup files)
  -k, --check          check that the files owned by the package(s) are present
  -l, --list           list the contents of the queried package
  -m, --foreign        list installed packages not found in sync db(s) [filter]
  -o, --owns <file>    query the package that owns <file>
  -p, --file <package> query a package file instead of the database
  -s, --search <regex> search locally-installed packages for matching strings
  -t, --unrequired     list packages not required by any package [filter]
  -u, --upgrades       list outdated packages [filter]
  -q, --quiet          show less information for query and search
      --config <path>  set an alternate configuration file
      --logfile <path> set an alternate log file
      --noconfirm      do not ask for any confirmation
      --noprogressbar  do not show a progress bar when downloading files
      --noscriptlet    do not execute the install scriptlet if one exists
  -v, --verbose        be verbose
      --debug          display debug messages
  -r, --root <path>    set an alternate installation root
  -b, --dbpath <path>  set an alternate database location
      --cachedir <dir> set an alternate package cache location
END_HELP
}

1;
