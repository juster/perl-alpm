package ALPM::FileConflict v1.0.0;

use strict;
use warnings;

sub target { return $_[0]->{target}; }

sub file { return $_[0]->{file}; }

sub ctarget { return $_[0]->{ctarget}; }

package ALPM::FileConflict::Target v1.0.0;
use parent -norequire, 'ALPM::FileConflict';

package ALPM::FileConflict::Filesystem v1.0.0;
use parent -norequire, 'ALPM::FileConflict';

1;
