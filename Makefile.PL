use ExtUtils::MakeMaker;
use warnings;
use strict;

# Avoid useless FAIL reports from CPAN Testers...
require DynaLoader;
unless(DynaLoader::dl_findfile('-lalpm')){
    print STDERR "ERROR: pacman/libalpm must be installed to compile ALPM!\n";
    exit 0;
}

sub MY::postamble {
    return <<'END_MAKE';
ALPM.xs: xs/DB.xs xs/Package.xs xs/Options.xs xs/Exception.xs
END_MAKE
}

my %meta = ('resources' => { 'repository' => 'http://github.com/juster/perl-alpm' });
WriteMakefile(
	'NAME' => 'ALPM',
	'VERSION_FROM' => 'lib/ALPM.pm',
	'LICENSE' => 'perl',
	'ABSTRACT_FROM' => 'lib/ALPM.pod',
	'AUTHOR' => 'Justin Davis <juster at cpan dot org>',
	'LIBS' => [ '-lalpm' ],
	'META_MERGE' => \%meta,
	'clean' => { 'FILES' => 't/root t/repos/share const-*.inc' },
	'OBJECT' => 'ALPM.o types.o cb.o exception.o',
	'XS' => { 'ALPM.xs' => 'ALPM.c' },
);
