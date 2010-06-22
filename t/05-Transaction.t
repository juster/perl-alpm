#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 13;

use File::Spec::Functions qw(rel2abs);
use ALPM qw(t/test.conf);

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
    my ($event) = @_;
    if ( $event->{status} eq 'done' ) {
        my $name = $event->{name};
        $event_is_done{ $name } = 1;
    }
}

sub check_events
{
    ok( ( 0 == grep { ! $_ } map { delete $event_is_done{$_} } @_ ),
        sprintf 'transaction events (%s) are done', join ',', @_ );
}

#ALPM->set_opt( 'logcb', \&print_log );

ok( ALPM->register_db( 'simpletest',
                       'file://' . rel2abs( 't/repos/share/simpletest' )) );

ok( my $t = ALPM->transaction( event => \&event_log ),
   'create a sync transaction' );

ok( $t->sync( 'foo' ), 'add foo package to transaction' );

eval { $t->sync('nonexistantpackage') };
like( $@, qr/^ALPM Error: could not find or read package/,
      'cannot load a non-existing package' );

ok( $t->prepare, 'prepare a transaction' );

check_events( qw/resolvedeps interconflicts/ ),

ok( $t->prepare, 'redundant prepare is ignored' );

eval { $t->sync('foo') };
like( $@, qr/duplicate target/,
      'cannot sync the same package twice' );

ok( $t->commit, 'commit the transaction' );

check_events( qw/integrity fileconflicts add/ );

undef $t;

$t = ALPM->transaction( flags => 'cascade dbonly dlonly' );
my $flags = $t->get_flags;
diag $flags;
like( $flags, qr/cascade/ );
like( $flags, qr/dbonly/  );
like( $flags, qr/dlonly/  );
