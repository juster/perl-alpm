package ALPM::DB;

use warnings;
use strict;

use ALPM;
use Carp qw(croak);
use English qw(-no_match_vars);

# Wrapper to automatically create a transaction...
sub update
{
    my $self = shift;

    croak "ALPM DB Error: cannot update database with an active transaction"
        if ( $ALPM::_Transaction );

    my $t = ALPM->transaction();
    eval { $self->_update(1) };
    if ( $EVAL_ERROR ) {
        $EVAL_ERROR =~ s/ at .*? line \d+[.]\n//;
        croak $EVAL_ERROR;
    }
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

__END__

=begin LICENSE

Copyright (C) 2011 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=end LICENSE
