package ALPM::FileList v1.0.0;

use strict;
use warnings;

use List::Util qw( first );

sub files { return @{ $_[0] }; }

sub count { return scalar @{ $_[0] }; }

sub contains {
	# FIXME: inefficient, switch to binary search or alpm_filelist_contains
	my ( $self, $path ) = @_;
	return first { $_ eq $path } @{$self};
}

1;
