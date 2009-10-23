package ALPM::DB;

use ALPM;
use Carp qw(croak);
use English qw(-no_match_vars);

# Wrapper to automatically create a transaction...
sub update
{
    my $self = shift;

    croak "ALPM DB Error: cannot update database with an active transaction"
        if ( $ALPM::_Transaction );

    my $t = ALPM->transaction( type => 'sync' );
    $self->_update(1);
    return 1;
}

# Wrapper to keep ALPM from crashing...
sub url
{
    my $self = shift;

    return undef if ( $self->name eq 'local' );
    return $self->_url;
}

# Wrapper so people don't have to use arrayrefs.
sub search
{
    my $self = shift;

    my $result = eval { $self->_search( [ @_ ] ) };

    if ( $EVAL_ERROR ) {
        die "$EVAL_ERROR\n" unless ( $EVAL_ERROR =~ /\AALPM Error:/ );
        $EVAL_ERROR =~ s/ at .*? line \d+[.]\n//;
        croak $EVAL_ERROR;
    }

    return @{ $result };
}

sub packages
{
    my $self = shift;

    return @{ $self->_get_pkg_cache() };
}

*pkgs = \&packages;

sub groups
{
    my $self = shift;
    return @{ $self->_get_group_cache() };
}

1;
