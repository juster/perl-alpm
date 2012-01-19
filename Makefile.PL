use ExtUtils::MakeMaker;
use File::Spec::Functions qw(catfile);

# Avoid FAIL reports from CPAN Testers...
require DynaLoader;
unless ( DynaLoader::dl_findfile( '-lalpm' )) {
    print STDERR "ERROR: pacman/libalpm must be installed for this module\n";
    exit 0;
}

WriteMakefile
    ( NAME              => 'ALPM',
      VERSION_FROM      => 'lib/ALPM.pm', # finds $VERSION
      PREREQ_PM         => { map { ( $_ => 0 ) }
                             qw/ Scalar::Util English Carp /
                            },
      BUILD_REQUIRES    => { File::Path => '2.06_05',
                             map { ( $_ => 0 ) }
                             qw{ File::Spec::Functions
                                 File::Copy     File::Find
                                 File::Basename File::stat
                                 Net::Ping      Time::HiRes
                                 Cwd }
                            },
      LICENSE           => 'perl',
      ABSTRACT_FROM     => 'lib/ALPM.pod',
      AUTHOR            => 'Justin Davis <juster at cpan dot org>',
      LIBS              => [ '-lalpm' ],
      META_MERGE        =>
      { resources =>
        { repository => 'http://github.com/juster/perl-alpm' }},
      clean             => { FILES  => 't/root t/repos/share const-*.inc' },
	# Un-comment this if you add C files to link with later:
     # OBJECT            => '$(O_FILES)', # link all the C files too
      OBJECT            => 'ALPM.o convert.o callbacks.o',
      XS                => { 'ALPM.xs' => 'ALPM.c' },
);
