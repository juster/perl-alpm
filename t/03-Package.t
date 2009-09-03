#!perl

use warnings;
use strict;

use Test::More tests => 27;

#use Data::Dumper;

BEGIN { use_ok('ALPM', root        => '/',
                       dbpath      => '/var/lib/pacman/',
                       cachedirs   => '/var/cache/pacman/pkg',
                       logfile     => '/var/log/pacman.log',
               );
}


ok( my $local = ALPM->register_db );

my $pkg = $local->find('perl');

my @methnames = qw{ compute_requiredby name version desc
                    url builddate installdate packager
                    arch arch size isize reason
                    licenses groups depends optdepends
                    conflicts provides deltas replaces
                    files backup };

for my $methodname (@methnames) {
    my $method_ref = $ALPM::Package::{$methodname};
    my $result = $method_ref->($pkg);
    ok $result;
}

my $attribs_ref = $pkg->attribs_ref;
ok( $attribs_ref );
ok( ref $attribs_ref eq 'HASH' );

