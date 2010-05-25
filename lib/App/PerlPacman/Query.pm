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

sub run_opts
{
    my ($class, $args_ref, %opts) = @_;

    # Check if an unrecognized option is leftover...
    my ($badopt) = grep { /\A-/ } @$args_ref;
    $class->fatal( qq{unrecognized option: '$badopt'} ) if $badopt;

    # 1. Convert arguments to package objects (or use all packages/groups)
    # 2. Filter out packages based on command-line options
    # 3. Print more info depending on command-line options
    my ($converter, $defprinter) = $class->create_conv_print( %opts );
    my $printer  = $class->create_printer( %opts ) || $defprinter;
    my $filter   = $class->create_filter( %opts );

    for my $pkg ( grep { $filter->() } $converter->( $args_ref ) ) {
        $printer->( $pkg );
    }

    return 0;
}

##----------------------------------------------------------------------------
## CONVERTERS
##----------------------------------------------------------------------------

# Create a converter sub that translates arguments to objects.
sub create_conv_print
{
    my ($class, %opts) = @_;

    # Converts groups to a list of packages, the printer still remembers
    # which group the package came from...
    if ( $opts{'groups'} ) {
        my %group_of;

        my $converter = sub {
            my $name = shift;
            my ($group_obj) = grep { $_->name eq $name }
                ALPM->localdb->groups;
            return undef unless $group_obj;

            # This reverse lookup is used when printing packages...
            $group_of{ $_->name } = $group_obj->name
                for $group_obj->packages;

            return $group_obj->packages;
        };

        my $printer_ref = sub {
            my $pkg  = shift;

            my $name = $pkg->name;
            printf "%s %s\n", $group_of{$name}, $name;
        };

        my $convert_ref = sub {
            _convert_args_to_objs
                ( args      => shift,
                  converter => $converter,
                  defaults  => sub {
                      map { 
                          for my $pkg ( $_->pkgs ) {
                              $group_of{ $pkg->name } = $_->name;
                          }
                          $_->pkgs;
                      } ALPM->localdb->groups;
                  },
                  error     => 'group %s was not found',
                 );
        };

        return ( $convert_ref, $printer_ref );
    }

    # Packages are simpler...
    my $convert_ref = sub {
        _convert_args_to_objs
            ( args      => shift,
              converter => sub { ALPM->localdb->find( shift ) },
              defaults  => sub { ALPM->localdb->packages },
              error     => 'package %s not found' );
    };

    my $printer_ref = sub {
        my $pkg = shift;
        printf "%s %s\n", $pkg->name, $pkg->version;
    };

    return ( $convert_ref, $printer_ref );
}


sub _convert_args_to_objs
{

    my %param = @_;

    my @found;

    my $args_ref   = $param{'args'};
    my $lookup_ref = $param{'converter'};
    return $param{'defaults'}->() unless @$args_ref;

    FINDOBJ_LOOP:
    for my $objname ( @$args_ref ) {
        my @objs = $lookup_ref->( $objname );
        unless ( @objs ) {
            __PACKAGE__->error( sprintf $param{'error'}, $objname );
            next FINDOBJ_LOOP;
        }
        push @found, @objs;
    }

    return @found;
}

##----------------------------------------------------------------------------
## PRINTERS
##----------------------------------------------------------------------------

sub create_printer
{
    my ($class, %opts) = @_;

    my $printer_result;

    my $append = sub {
        my $newprinter = shift;
        my $oldprinter = $printer_result || sub { };
        $printer_result = sub {
            my $obj = shift;
            $newprinter->( $obj );
            $oldprinter->( $obj );
        }
    };

    my $printer = sub {
        my $optname = shift;
        return unless $opts{ $optname };
        $append->( shift );
    };

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

    return $printer_result;
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

##----------------------------------------------------------------------------
## FILTERS
##----------------------------------------------------------------------------

# Creates a closure that will run all filters on $_ (a package object)
# The closure returns 1 if it is not filtered out, 0 if it is.
sub create_filter
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

    return sub {
        # $_ is our package object to check!
        for my $filter ( @filters ) {
            return 0 unless $filter->();
        }

        return 1
    }
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

1;
