use ExtUtils::MakeMaker;
use warnings;
use strict;

# Avoid useless FAIL reports from CPAN Testers...
require DynaLoader;
unless(DynaLoader::dl_findfile('-lalpm')){
    print STDERR "ERROR: pacman/libalpm must be installed to compile ALPM!\n";
    exit 0;
}

my %reqs = map { ($_ => 0) } qw/Scalar::Util English Carp/;
my %breqs = map { ($_ => 0) } qw{File::Spec::Functions File::Copy File::Find File::Basename
	File::stat Net::Ping Time::HiRes Cwd};
$breqs{'File::Path'} = '2.06_05';
my %meta = ('resources' => { 'repository' => 'http://github.com/juster/perl-alpm' });

sub MY::postamble {
    return <<'END_MAKE';
ALPM.xs: xs/DB.xs xs/Package.xs xs/Options.xs
END_MAKE
}

WriteMakefile(
	'NAME' => 'ALPM',
	'VERSION_FROM' => 'lib/ALPM.pm',
	'PREREQ_PM' => \%reqs,
	'BUILD_REQUIRES' => \%breqs,
	'LICENSE' => 'perl',
	'ABSTRACT_FROM' => 'lib/ALPM.pod',
	'AUTHOR' => 'Justin Davis <juster at cpan dot org>',
	'LIBS' => [ '-lalpm' ],
	'META_MERGE' => \%meta,
	'clean' => { 'FILES' => 't/root t/repos/share const-*.inc' },
	'OBJECT' => 'ALPM.o types.o cb.o',
	'XS' => { 'ALPM.xs' => 'ALPM.c' },
);

system 'perl' => 't/preptests.pl';
