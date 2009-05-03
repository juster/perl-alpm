#!perl

use warnings;
use strict;

use Test::More tests => 15;
use Data::Dumper;
use Net::Ping;

BEGIN { use_ok('ALPM'); }

ok( ALPM->set_options({ root        => '/',
                        dbpath      => '/var/lib/pacman/',
                        cachedirs   => [ '/var/cache/pacman/pkg' ],
                        logfile     => '/var/log/pacman.log',
                        xfercommand => '/usr/bin/wget --passive-ftp -c -O %o %u' }) );

ok( my $local = ALPM->register_db );

is( $local->get_name, 'local' );

is( $local->get_pkg('lskdfjkbadpkgname'), undef );

ok( $local->get_pkg('perl')->isa('ALPM::Package') );
is( ref $local->get_pkg_cache, 'ARRAY' );
is( ref $local->get_group_cache, 'ARRAY' );
is( ref $local->search(['perl']), 'ARRAY' );

SKIP:
{
    my $pinger = Net::Ping->new;
    skip 'could not ping ftp.archlinux.org', 6
        unless $pinger->ping('ftp.archlinux.org');

    my $name = 'core';
    my $syncdb = ALPM->register_db( $name => 'ftp://ftp.archlinux.org/$repo/os/i686' );
    ok( $syncdb );
    is( $syncdb->get_name, $name );
    is( ref $syncdb->get_pkg_cache, 'ARRAY' );
    is( ref $syncdb->get_group_cache, 'ARRAY' );

    ok( $syncdb->get_pkg('perl')->isa('ALPM::Package') );
    is( ref $syncdb->search(['perl']), 'ARRAY' );
}
