#!/usr/bin/perl

# This stub package is only here to create the PackageFree class.
# We need this file to have PackageFree inherit everything from Package.
# The only difference with PackageFree is that it frees its own memory
# when it is DESTROYed.  This is done in the ALPM.xs file.

package ALPM::PackageFree;

use warnings;
use strict;

use base qw(ALPM::Package);

1;
