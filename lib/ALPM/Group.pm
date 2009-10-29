package ALPM::Group;

use warnings;
use strict;

use ALPM;

sub packages {
    my $self = shift;
    return @{ $self->_get_pkgs };
}

*pkgs = \&packages;

1;
