#!perl

use warnings;
use strict;

use Test::More tests => 26;
use Data::Dumper;

BEGIN { use_ok('ALPM', root        => '/',
                       dbpath      => '/var/lib/pacman/',
                       cachedirs   => '/var/cache/pacman/pkg',
                       logfile     => '/var/log/pacman.log',
                       xfercommand => '/usr/bin/wget --passive-ftp -c -O %o %u' ) } ;

ok( my $local = ALPM->register_db );

my $pkg = $local->get_pkg('perl');

my @methnames = qw{ compute_requiredby get_name get_version get_desc
                    get_url get_builddate get_installdate get_packager
                    get_arch get_arch get_size get_isize get_reason
                    get_licenses get_groups get_depends get_optdepends
                    get_conflicts get_provides get_deltas get_replaces
                    get_files get_backup };

for my $methodname (@methnames) {
    my $method_ref = $ALPM::Package::{$methodname};
    my $result = $method_ref->($pkg);
    ok $result;
}

my $attribs_ref = $pkg->get_attribs_ref;
ok( $attribs_ref );

