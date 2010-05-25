package App::PerlPacman::Query;
use base qw(App::PerlPacman);

use warnings;
use strict;

use Text::Wrap;
use ALPM;

sub option_spec
{
    qw{ changelog|c deps|d explicit|e groups|g info|i check|k list|l foreign|m 
        owns|o:s file|p:s search:s unrequired|t upgrades|u quiet|q
        config|c:s logfile|l:s noconfirm noprogressbar noscriplet
        verbose|v debug root|r dbpath|b cachedir };
}

sub _print_info
{
    my $pkg = shift;

    my %info = $pkg->attribs;
    $info{'desc'} = Text::Wrap::wrap( 'Description    : ',
                                      '                 ',
                                      $info{'desc'} );

    for my $pluralkey ( grep { /s\z/ } keys %info ) {
        my $aref = $info{ $pluralkey };
        $info{ $pluralkey } = ( @$aref ? join q{ }, @$aref : 'None' );
    }

    $info{'reason'}        = ucfirst $info{'reason'} . 'ly installed.';
    $info{'has_scriptlet'} = ( $info{'has_scriptlet'} ? 'Yes' : 'No' );

    return <<"END_INFO";
Name           : $info{'name'}
Version        : $info{'version'}
URL            : $info{'url'}
Licenses       : $info{'licenses'}
Groups         : $info{'groups'}
Provides       : $info{'provides'}
Depends On     : $info{'depends'}
Optional Deps  : $info{'optdepends'}
Required By    : $info{'requiredby'}
Conflicts With : $info{'conflicts'}
Replaces       : $info{'replaces'}
Installed Size : $info{'isize'}
Packager       : $info{'packager'}
Architecture   : $info{'arch'}
Build Date     : $info{'builddate'}
Install Date   : $info{'installdate'}
Install Reason : $info{'reason'}
Install Script : $info{'has_scriptlet'}
$info{'desc'};
END_INFO
}

sub make_printer
{
    my (%opts) = @_;

    my $print_ref = sub {}; # null sub

    my $append = sub {
        my $newprinter = shift;
        my $oldprinter = $print_ref;
        $print_ref = sub {
            my $obj = shift;
            $newprinter->( $obj );
            $oldprinter->( $obj );
        }
    };

    my $use_default = 1;
    my $printer = sub {
        my $optname = shift;
        return unless $opts{ $optname };
        $use_default = 0;
        $append->( shift );
    };

    $printer->( 'groups' =>
                sub {
                    my $group = shift;
                    my $name  = $group->name;
                    for my $package ( $group->packages ) {
                        printf "%s %s\n", $name, $package->name;
                    }
                } );

    # Ignore other options if --group is set...
    return $print_ref if $opts{ 'groups' };

    $printer->( 'info' => \&_print_info );
    $printer->( 'changelog' => sub {
                    my $pkg = shift;
                    my $changelog = $pkg->changelog;
                    if ( $changelog ) {
                        print $changelog;
                    }
                    else {
                        my $name = $pkg->name;
                        __PACKAGE__->error
                            ( q{no changelog available for } .
                              qq{'$name'} );
                    }
                } );

    if ( $use_default ) {
        $append->( sub {
                       my $pkg = shift;
                       printf "%s %s\n", $pkg->name, $pkg->version;
                   } );
    }

    return $print_ref;
}

sub convert_args
{
    my ($args_ref, $lookup_ref, $default_ref, $missing_fmt) = @_;

    my @found;

    return $default_ref->() unless @$args_ref;

    FINDOBJ_LOOP:
    for my $objname ( @$args_ref ) {
        my $obj = $lookup_ref->( $objname );
        unless ( $obj ) {
            __PACKAGE__->error( sprintf $missing_fmt, $objname );
            next FINDOBJ_LOOP;
        }
        push @found, $obj;
    }

    return @found;
}

sub convert_args_by_opts
{
    my ($args_ref, %opts) = @_;

    if ( $opts{'groups'} ) {
        my $converter = sub {
            my $name = shift;
            my ($obj)
                = grep { $_->name eq $name }
                    ALPM->localdb->groups;
            $obj
        };

        return convert_args( $args_ref, $converter,
                             sub { ALPM->localdb->groups },
                             'group %s was not found',
                            );
    }

    return convert_args( $args_ref,
                         sub { ALPM->localdb->find( shift ) },
                         sub { ALPM->localdb->packages },
                         'package %s not found',
                        );
}

sub run_opts
{
    my ($class, $args_ref, %opts) = @_;

    # Check if an unrecognized option is leftover...
    my ($badopt) = grep { /\A-/ } @$args_ref;
    $class->fatal( qq{unrecognized option: '$badopt'} ) if $badopt;

    my @packages = convert_args_by_opts( $args_ref, %opts );
    filter_packages( \@packages, %opts );
    my $printer = make_printer( %opts );
    $printer->( $_ ) foreach @packages;

    return 0;
}

sub filter_packages
{
    my ($packages_ref, %opts) = @_;

    my $filters_ref = create_filters( %opts );
    filtration( $filters_ref, $packages_ref );

    # Not necessary, because we alter reference in place...
    return $packages_ref;
}

sub filtration
{
    my ($filters_ref, $packages_ref) = @_;

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

sub create_filters
{
    my (%opts) = @_;

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
