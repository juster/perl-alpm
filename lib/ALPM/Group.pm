package ALPM::Group;

use warnings;
use strict;

sub packages {
    my $self = shift;
    return @{ $self->_get_pkgs };
}

*pkgs = \&packages;

1;

__END__

=head1 NAME

ALPM::Group - ALPM package group class.

=head1 SYNOPSIS

  use ALPM qw(/etc/pacman.conf);
  
  for $grp ( ALPM->localdb->groups ) {
      print $grp->name(), "\n",
        map { " - $_\n" } map { $_->name } $grp->packages;
  }

=head1 METHODS

=head2 name

 $NAME = $group_obj->name()

=head3 Parameters

None

=head3 Returns

=over 4

=item C<$NAME>

The name of the group.

=back

=head2 pkgs = packages

 @PKGS = $group_obj->pkgs()
 @PKGS = $group_obj->packages()

=head3 Parameters

None

=head3 Returns

=over 4

=item C<@PKGS>

A list of L<ALPM::Package> objects who are in the group.

=back

=head1 SEE ALSO

L<ALPM::DB>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
