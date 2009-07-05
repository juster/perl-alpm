#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

use Data::Dumper;

use ALPM qw(t/fakeroot/etc/pacman.conf);

ok( ALPM->register_db );
ok( my $t = ALPM->transaction( type => 'sync' ) );

$t->prepare;
$t->prepare;
eval { $t->add('test') };
ok( $@ =~ /cannot add more targets/ );

eval { ok( $t->commit ) };
print STDERR Dumper($t);
