#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

use ALPM qw(t/fakeroot/etc/pacman.conf);

my $logstr;

sub print_log
{
    my ($lvl, $msg) = @_;
    $logstr .=  join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
}

#use Data::Dumper;

sub event_log
{
    my ($event) = @_;
#    print STDERR Dumper( $event );
}

ALPM->set_opt( 'logcb', \&print_log );

ok( my $t = ALPM->transaction( type => 'sync', event => \&event_log ) );

ok( $t->prepare, 'prepare a transaction' );
ok( $t->prepare, 'redundant prepare is ignored' );

eval { $t->add('nonexistantpackage') };
ok( $@ =~ /ALPM Error/ );
ok( length $logstr > 0 );
$logstr = '';

eval { $t->commit };
ok( $@ =~ /ALPM Error/ );
ok( length $logstr  > 0 );

$t = undef;

# ok( $t = ALPM->transaction( type => 'sync' ) );
# ok( $t->add('bar') );
# ok( $t->commit );
