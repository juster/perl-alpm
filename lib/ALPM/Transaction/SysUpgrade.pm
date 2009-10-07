package ALPM::Transaction::SysUpgrade;

use warnings;
use strict;

# Maybe we should still do this for isa()'s check?
#use base qw(ALPM::Transaction);

use Carp;

# Prevent ALPM::Transaction's DESTROY (in ALPM.xs) from being called.
#sub DESTROY { return; }

sub new
{
    my $class       = shift;
    my ($downgrade) = @_;

    bless { type             => 'sysupgrade',
            enable_downgrade => $downgrade }, $class;
}

sub add {
    croak q{You cannot add packages to a transaction of type 'sysupgrade'};
}

sub prepare { return 1; }

sub commit {
    my ($self) = @_;
    return _sysupgrade( $self->{enable_downgrade} );
}

1;

__END__

=head1 CLASS

ALPM::Transaction::SysUpgrade

=head1 DESCRIPTION

This is a simple wrapper that resembles a normal transaction object.
An object of this class is returned when you request a transaction
of type 'sysupgrade'.

  my $t = ALPM->transaction( type  => 'sysupgrade',
                             flags => [ 'downgrade' ] );
  print ref $t, "\n";
