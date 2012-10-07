package ALPM;

#use 5.010000;
use strict;
use warnings;

use AutoLoader;

use Scalar::Util qw(weaken);
use English      qw(-no_match_vars);
use Carp         qw(carp croak confess);

use ALPM::Transaction;
use ALPM::Package;
use ALPM::DB;

our $VERSION = '2.01';

require XSLoader;
XSLoader::load('ALPM', $VERSION);


####----------------------------------------------------------------------
#### GLOBAL VARIABLES
####----------------------------------------------------------------------


# Transaction global variable
our $_Transaction;

our @GET_SET_OPTS = qw{ root dbpath cachedirs logfile usesyslog
                        noupgrades noextracts ignorepkgs ignoregrps
                        logcb dlcb totaldlcb fetchcb usedelta arch };

our %_IS_SETOPTION = ( map { ( $_ => 1 ) } @GET_SET_OPTS );
our %_IS_GETOPTION = ( map { ( $_ => 1 ) } @GET_SET_OPTS,
                       qw/ lockfile localdb syncdbs / );

### Transaction Constants ###
our %_TRANS_FLAGS = (
	'nodeps' => (1 << 0),
	'force' => (1 << 1),
	'nosave' => (1 << 2),
	'nodepver' => (1 << 3),
	'cascade' => (1 << 4),
	'recurse' => (1 << 5),
	'dbonly' => (1 << 6),
	'alldeps' => (1 << 8),
	'dlonly' => (1 << 9),
	'noscriptlet' => (1 << 10),
	'noconflicts' => (1 << 11),
	'needed' => (1 << 13),
	'allexplicit' => (1 << 14),
	'unneeded' => (1 << 15),
	'recurseall' => (1 << 16),
	'nolock' => (1 << 17),
);


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

    croak 'Option name must be provided'
        unless defined $optname;

    croak qq{Unknown libalpm option "$optname"}
        unless ( $_IS_GETOPTION{$optname} );

    my $method_name = "alpm_option_get_$optname";
    my $func_ref = $ALPM::{$method_name};

    die "Internal error: $method_name should be defined in ALPM.xs"
        unless defined $func_ref;

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

    croak 'Option name must be provided'
        unless defined $optname;

    $optname = lc $optname;
    unless ( $_IS_SETOPTION{$optname} ) {
        carp qq{Given option "$optname" is not settable or unknown};
        return;
    }

    my $method_name = "alpm_option_set_$optname";
    my $func_ref = $ALPM::{$method_name};

    die "Internal error: $method_name should be defined in ALPM.xs"
        unless defined $func_ref;

    my $func_arg;

    # If the option is a plural, it can accept multiple arguments
    # and must take an arrayref as argument...
    if ( substr( $optname, -1 ) eq 's'  ) {
        $func_arg = ( ! defined $optval
                      ? [ ] # XSUB must have an array ref
                      : ref $optval eq 'ARRAY'
                      ? $optval
                      # auto-convert args to aref
                      : ( [ $optval, @_[ 3 .. $#_ ] ] ));
    }
    else {
        $func_arg = $optval;
    }

    # I think the XSUB checks this for us.
    #
    # else {
    #     # is single valued opt
    #     croak qq{Singular option "$optname" only takes a scalar value}
    #         unless ( ! ref $optval || ref $optval eq 'CODE' );
    # }

    eval { $func_ref->($func_arg) };

    if ( $EVAL_ERROR ) {
        $EVAL_ERROR =~ s/ at .*? line \d+[.]\n//;
        croak $EVAL_ERROR;
    }
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
        eval { $class->set_opt( $optname, $options{$optname} ) };
        if ( $EVAL_ERROR ) {
            $EVAL_ERROR =~ s/ at .*? line \d+\n//;
            croak "$EVAL_ERROR (for $optname)";
        }
    }

    return 1;
}

sub localdb
{
    my $class = shift;
    return $class->get_opt('localdb');
}

sub syncdbs
{
    my $class = shift;
    return @{ $class->get_opt('syncdbs') };
}

sub dbs
{
    my $class = shift;
    return ( $class->localdb, $class->syncdbs );
}

sub db
{
    croak 'Not enough arguments to ALPM::repodb()' if ( @_ < 2 );
    my ($class, $repo_name) = @_;

    my ($found) = grep { $_->name eq $repo_name } $class->dbs;
    return $found;
}

sub search
{
    my ($class, @search_strs) = @_;

    return ( map { $_->search( @search_strs ) } $class->databases );
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

sub load_pkgfile
{
    croak 'load_pkgfile() must have at least a filename as argument'
        if ( @_ < 1 );

    if ( eval { $_[0]->isa( __PACKAGE__ ) } ) {
        shift @_;
    }

    my $package_path = shift;
    my $pkgobj = eval { _pkg_load( $package_path ) };
    return $pkgobj unless $@;

    $@ =~ s/ at .*? line \d+[.]\n\z//;
    croak $@;
}

sub trans
{
    croak 'trans() must be called as a class method' unless ( @_ );
    my $class = shift;

    croak 'arguments to trans method must be a hash'
        unless ( @_ % 2 == 0 );

    my %trans_opts  = @_;
    my $trans_flags = 0;

    # Parse flags if they are provided...
    if ( exists $trans_opts{flags} ) {
        for my $flag ( split /\s+/, $trans_opts{flags} ) {
            croak qq{unknown transaction flag "$flag"}
                unless exists $_TRANS_FLAGS{$flag};
            $trans_flags |= $_TRANS_FLAGS{$flag};
        }
    }

    eval {
        _trans_init( $trans_flags,
                     $trans_opts{event},
                     $trans_opts{conv},
                     $trans_opts{progress});
    };
    if ( $EVAL_ERROR ) {
        die "$EVAL_ERROR\n" unless ( $EVAL_ERROR =~ /\AALPM Error:/ );
        $EVAL_ERROR =~ s/ at .*? line \d+[.]\n//;
        croak $EVAL_ERROR;
    }

    # Create an object that will automatically release the transaction
    # when destroyed...
    my $t = ALPM::Transaction->new( %trans_opts );
    $_Transaction = $t;   # keep track of active transactions
    weaken $_Transaction;
    return $t;
}


####----------------------------------------------------------------------
#### TIED HASH INTERFACE
####----------------------------------------------------------------------


my @_OPT_NAMES = sort keys %ALPM::_IS_GETOPTION;

sub TIEHASH
{
    my $class = shift;
    bless { 'KEY_ITER' => 0 }, $class;
}

sub DESTROY
{
    1;
}

sub EXISTS
{
    return exists $ALPM::_IS_GETOPTION{ $_[1] };
}

sub DELETE
{
    my ($self, $key) = @_;
    $self->set_opt( $key, undef );
}

sub CLEAR
{
    croak 'You cannot empty this tied hash';
}

sub FETCH
{
    my ($self, $key) = @_;
    return $self->get_opt( $key );
}

sub STORE
{
    my ($self, $key, $value) = @_;
    return $self->set_opt( $key, $value );
}

sub FIRSTKEY
{
    my ($self) = @_;

    $self->{KEY_ITER} = 1;
    return $_OPT_NAMES[0];
}

sub NEXTKEY
{
    my ($self) = @_;

    return ( $self->{KEY_ITER} < scalar @_OPT_NAMES
             ? $_OPT_NAMES[ $self->{KEY_ITER}++ ]
             : undef );
}

1;

__END__
