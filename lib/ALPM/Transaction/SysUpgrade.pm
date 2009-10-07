package ALPM::Transaction::SysUpgrade;

use warnings;
use strict;
use base qw(ALPM::Transaction);

# Prevent ALPM::Transaction's DESTROY (in ALPM.xs) from being called.
sub DESTROY { return; }

1;

__END__

=head1 CLASS

ALPM::Transaction::SysUpgrade

=head1 DESCRIPTION

This class is here to give the transaction methods to a sysupgrade
transaction object.  This class also prevents the transaction from
being released when it is destroyed.

An object of this class is returned when you request a transaction
of type 'sysupgrade'.

  my $t = ALPM->transaction( type  => 'sysupgrade',
                             flags => [ 'downgrade' ] );
  print ref $t, "\n";
