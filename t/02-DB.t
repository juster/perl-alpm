#!perl

use warnings;
use strict;

use Test::More tests => 15;
use Net::Ping;
use Time::HiRes qw(sleep);

BEGIN { use_ok('ALPM'); }

ok( ALPM->set_options({ root        => '/',
                        dbpath      => '/var/lib/pacman/',
                        cachedirs   => [ '/var/cache/pacman/pkg' ],
                        logfile     => '/var/log/pacman.log', }) );


ok( my $local = ALPM->register_db );

is( $local->name, 'local' );

is( $local->find('lskdfjkbadpkgname'), undef );

ok( $local->find('perl')->isa('ALPM::Package') );

ok( scalar $local->packages > 1 );
ok( scalar $local->groups > 1 );
#is( ref $local->search('perl'), 'ARRAY' );

diag 'testing with ftp.archlinux.org repository';

SKIP:
{
    my $pinger = Net::Ping->new;
    my $success = 0;
    for ( 1 .. 5 ) {
        if ( $pinger->ping('ftp.archlinux.org') ) {
            $success = 1;
            last;
        }
        sleep 0.5;
    }
    skip 'could not ping ftp.archlinux.org', 7 unless $success;

    my $name = 'core';
    my $syncdb = ALPM->register_db( $name =>
                                    'ftp://ftp.archlinux.org/$repo/os/i686' );
    ok( $syncdb );
    is( $syncdb->name, $name );
    ok( scalar $syncdb->packages > 1 );
    ok( scalar $syncdb->groups > 1 );

    ok( $syncdb->find('perl')->isa('ALPM::Package') );
    ok( scalar $syncdb->search('perl') > 1 );

    is( 1, scalar ALPM->syncdbs );
}
