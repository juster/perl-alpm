#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 3;
use File::Spec::Functions qw(catfile);

use ALPM;

my $pkg_path = catfile( qw/ t repos share simpletest
                            foo-1.0-1-any.pkg.tar.xz / );

# Can't get it to work...
# my $old_destroy   = *{ $ALPM::PackageFree::{'DESTROY'} }{CODE};
# my $was_destroyed = 0;
# {
#     no warnings 'redefine';
#     $ALPM::PackageFree::{'DESTROY'} = sub {
#         use Data::Dumper;
#         print STDERR Dumper \$@;
#         $was_destroyed = 1;

#         $old_destroy->( $@ );
#     };
# }

{
    my $pkg = ALPM->load_pkgfile( $pkg_path );
    ok $pkg;
    is $pkg->name, 'foo';
    is $pkg->arch, 'any';
}

