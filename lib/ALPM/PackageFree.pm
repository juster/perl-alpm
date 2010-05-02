#!/usr/bin/perl

package ALPM::PackageFree;

use warnings;
use strict;

use base qw(ALPM::Package);

1;

__END__

=head1 NAME

PackageFree - ALPM package class that frees itself from memory

=head1 DESCRIPTION

This stub package is only here to create the PackageFree class.
We need this file to have PackageFree inherit everything from Package.
The only difference with PackageFree is that it frees its own memory
when it is DESTROYed.  This is done in the ALPM.xs file.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
