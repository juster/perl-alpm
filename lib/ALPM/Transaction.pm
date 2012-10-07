package ALPM::Transaction;

use warnings;
use strict;
use Carp qw(carp croak);

# This is just a simple class method used to store the settings
# used to create the transaction and associate the hashref with
# this package.  Most of the functionality is in ALPM.xs.

sub new
{
    my $class = shift;

    my %trans_opts = @_;

    bless { prepared => 0,
            flags    => $trans_opts{flags},
            event    => $trans_opts{event},
           }, $class;
}

sub get_flags
{
    my ($self) = @_;

    my @flag_names;
    my $raw_flags = _trans_get_flags();
    FLAG_CHECK:
    while ( my ($flagname, $flagmask) = each %ALPM::_TRANS_FLAGS ) {
        next FLAG_CHECK unless $raw_flags & $flagmask;
        push @flag_names, $flagname;
    }

    return wantarray ? @flag_names : join q{ }, @flag_names;
}

sub get_additions
{
    my ($self) = @_;
    return @{ _trans_get_add() };
}

sub get_removals
{
    my ($self) = @_;
    return @{ _trans_get_remove() };
}

1;
