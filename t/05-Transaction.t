#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);

use Data::Dumper;

use ALPM qw(t/fakeroot/etc/pacman.conf);

sub print_log
{
    my ($lvl, $msg) = @_;
#    $log_lines .= join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
    print STDERR join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
}

ALPM->set_opt( 'logcb', \&print_log );

ok( my $t = ALPM->transaction( type => 'sync' ) );

ok( $t->prepare );
ok( $t->prepare );

eval { $t->add('nonexistantpackage') };
ok( $@ =~ /ALPM Error/ );

eval { $t->commit };
ok( $@ =~ /ALPM Error/ );

$t = undef;

ok( $t = ALPM->transaction( type => 'sync' ) );
ok( $t->add('bar') );
ok( $t->commit );
