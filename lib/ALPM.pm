package ALPM;

use 5.010000;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);
use English qw(-no_match_vars);
use Carp;

use ALPM::Package;
use ALPM::DB;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('ALPM', $VERSION);

initialize();

END { release() };

# TODO: logcb dlcb totaldlcb
my %_IS_GETSETOPTION = ( map { ( $_ => 1 ) }
                         qw{ root dbpath cachedirs logfile usesyslog
                             noupgrades noextracts ignorepkgs holdpkgs ignoregrps
                             xfercommand nopassiveftp } );

my %_IS_GETOPTION    = ( %_IS_GETSETOPTION,
                         map { ( $_ => 1 ) } qw/ lockfile localdb syncdbs / );

####----------------------------------------------------------------------
#### CLASS FUNCTIONS
####----------------------------------------------------------------------

sub import
{
    croak 'Invalid arguments to import function' if ( @_ == 0 );
    return if ( @_ == 1 );

    my ($class) = shift;

    if ( @_ == 1) {
        my $arg = shift;

        croak <<'END_ERROR' if ( ref $arg );
A single argument to ALPM's import must be a hash or a path to a
pacman.conf file
END_ERROR

        $class->load_config($arg);
        return;
    }

    croak q{Multiple options to ALPM's import must be a hash}
        unless ( @_ % 2 == 0 );

    $class->set_options( @_ );
    return;
}

####----------------------------------------------------------------------
#### CLASS METHODS
####----------------------------------------------------------------------

sub get_opt
{
    croak 'Invalid arguments to get_opt' if ( @_ != 2 );
    my ($class, $optname) = @_;

    croak qq{Unknown libalpm option "$optname"} unless ( $_IS_GETOPTION{$optname} );

    my $method_name = "get_$optname";
    my $func_ref = $ALPM::{$method_name};

    my $result = eval { $func_ref->() };
    if ($EVAL_ERROR) {
        # For ALPM errors, show the line number of the calling script, not
        # the line number of this module...
        croak $1 if ( $EVAL_ERROR =~ /^(ALPM .*) at .*? line \d+[.]$/ );
        croak $EVAL_ERROR;
    }

    return $result;
}

sub set_opt
{
    croak 'Not enough arguments to set_opt' if ( @_ < 3 );
    my ($class, $optname, $optval) = @_;

    $optname = lc $optname;
    unless ( $_IS_GETSETOPTION{$optname} ) {
        carp qq{Given option "$optname" is not settable or unknown};
        return;
    }

    my $method_name = "set_$optname";
    my $func_ref = $ALPM::{$method_name};
    my $func_arg;

    # If the option is a plural, it can accept multiple arguments
    # and must take an arrayref as argument...
    $func_arg = ( $optname =~ /s$/            ?
                  # is multivalue opt
                  ( ref $optval eq 'ARRAY'      ?
                    $optval                     :
                    ( [ $optval, @_[ 3 .. $#_ ] ] ) # auto-convert args to aref
                   )                          :
                  # is single valued opt
                  ( ! ref $optval                 ?
                    $optval                       :
                    croak qq{Singular option "$optname" only takes a scalar value}
                   )
                 );

    return $func_ref->($func_arg);
}

sub get_options
{
    my $class = shift;

    if ( @_ == 0 ) {
        return %{$class->get_options_ref};
    }
    return @{$class->get_options_ref(@_)};
}

sub get_options_ref
{
    my $class = shift;

    # Return a list if option names are specified...
    return [ map { $class->get_opt($_) } @_ ]
        if ( @_ > 0 );

    # Return a hash of all options if no names are given...
    my $opts = {};
    for my $optname ( keys %_IS_GETOPTION ) {
        $opts->{$optname} = $class->get_opt($optname);
    }
    return $opts;
}

sub set_options
{
    croak 'Invalid arguments to set_options' if @_ < 2;
    my $class = shift;

    my %options;
    if ( @_ % 2 == 0 ) { %options = @_; }
    else {
        eval { %options = %{shift()} }
            or croak 'Argument to set_options must be either a hash or hashref';
    }

    for my $optname ( keys %options ) {
        $class->set_opt( $optname, $options{$optname} );
    }

    return 1;
}

sub register_db
{
    my $class = shift;

    if ( @_ == 0 || $_[0] eq 'local' ) {
        return $class->local_db;
    }

    my ($sync_name, $sync_url) = @_;

    croak 'You must supply a URL for the database'
        unless ( defined $sync_url );

    # Replace the literal string '$repo' with the repo's name,
    # like in the pacman config file... bad idea maybe?
    $sync_url =~ s/\$repo/$sync_name/g;

    # Set the server right away because function calls break in between...
    my $new_db = db_register_sync($sync_name);
    $new_db->_set_server($sync_url);
    return $new_db;
}

sub local_db
{
    my $class = shift;
    my $localdb = $class->get_opt('localdb');
    return $localdb if $localdb;
    return db_register_local();
}

sub get_repo_db
{
    croak 'Not enough arguments to get_repo_dbs' if ( @_ < 2 );
    my ($class, $repo_name) = @_;

    my ($found) = grep { $_->get_name eq $repo_name } @{ALPM->get_opt('syncdbs')};
    return $found;
}

sub load_config
{
    my ($class, $cfg_path) = @_;

    require ALPM::LoadConfig;
    my $loader = ALPM::LoadConfig->new;
    eval { $loader->load_file($cfg_path) };

    croak $EVAL_ERROR . "Config file parse error" if ($EVAL_ERROR);

    return 1;
}

1;
