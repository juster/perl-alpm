package ALPM::Dependency v1.0.0;

use strict;
use warnings;

sub name { return $_[0]->{name}; }

sub version { return $_[0]->{version}; }

sub mod { return $_[0]->{mod}; }

1;
