#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

use File::Spec::Functions qw(rel2abs);
use ALPM qw(t/test.conf);

$ENV{'LANGUAGE'} = 'en_US';

my $logstr;

sub print_log
{
    my ($lvl, $msg) = @_;
    my $tmpstr = sprintf '[%10s] %s', $lvl, $msg;
    $logstr .= $tmpstr;
    print STDERR $tmpstr;
}

my %event_is_done;

sub event_log
{
    my $event = shift;
    $event_is_done{ $event->{'name'} } = $event->{'status'} eq 'done';
}

sub check_events
{
    ok delete $event_is_done{ $_ },
        qq{transaction event "$_ is done" was received} for @_;
}

#ALPM->set_opt( 'logcb', \&print_log );

ok( ALPM->register( 'simpletest',
                    'file://' . rel2abs( 't/repos/share/simpletest' )) );

ok( my $t = ALPM->trans( event => \&event_log ),
   'create a sync transaction' );

my $pkg;
$pkg = ALPM->db('simpletest')->find('foo');
ok( $t->install( $pkg ), 'add foo package to transaction' );

ok( $t->prepare, 'prepare a transaction' );

check_events( qw/resolvedeps interconflicts/ ),

ok( $t->prepare, 'redundant prepare is ignored' );

$pkg = ALPM->db('simpletest')->find('foo');
eval { $t->install($pkg) };
like( $@, qr/transaction not initialized/, # vague error message much?
      'cannot sync the same package twice' );

ok( $t->commit, 'commit the transaction' );

check_events( qw/integrity fileconflicts / );

ok grep { $_ } map { delete $event_is_done{$_} } qw/ add upgrade /,
    "package add or upgrade succeeded";

undef $t;

$t = ALPM->trans( flags => 'cascade dbonly dlonly' );
my $flags = $t->get_flags;
like( $flags, qr/cascade/ );
like( $flags, qr/dbonly/  );
like( $flags, qr/dlonly/  );

done_testing;

