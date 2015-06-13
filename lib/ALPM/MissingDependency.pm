package ALPM::MissingDependency v1.0.0;

use strict;
use warnings;

sub target { return $_[0]->{target}; }

sub causingpkg { return $_[0]->{causingpkg}; }

sub depend { return $_[0]->{depend}; }

1;
