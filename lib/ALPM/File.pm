package ALPM::File v1.0.0;

use strict;
use warnings;

sub name { return $_[0]->{name}; }

sub size { return $_[0]->{size}; }

sub mode { return $_[0]->{mode}; }

1;
