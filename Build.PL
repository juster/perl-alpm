use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ALPM',
    license             => 'perl',
    dist_author         => 'Justin Davis <jrcd83@gmail.com>',
    dist_version_from   => 'lib/ALPM.pm',
    build_requires => {
        'ExtUtils::CBuilder' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'ALPM-*' ],
#    create_makefile_pl  => 'traditional',
    extra_linker_flags  => [ '-lalpm' ],
);

$builder->create_build_script();
