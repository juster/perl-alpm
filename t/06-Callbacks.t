#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);
use ALPM qw(t/test.conf);
use Data::Dumper;
use File::Spec::Functions qw(rel2abs);
use Cwd;

my $log_lines = '';

sub print_log
{
    my ($lvl, $msg) = @_;
    $log_lines .= join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
#    print STDERR join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
}

ALPM->set_opt( 'logcb', \&print_log );

my $db = ALPM->register( 'simpletest' => rel2abs('t/repo/share') );
my $foopkg = $db->find('foo');

ok( length $log_lines );

