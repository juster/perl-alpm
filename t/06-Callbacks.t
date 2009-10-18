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

tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = \&print_log;

my $db = ALPM->register( 'simpletest' => rel2abs('t/repos/share') );
my $foopkg = $db->find('foo');

ok( length $log_lines );
ok( $foopkg );

#$alpm_opt{logcb} = undef;

sub create_cb_checker
{
    my $msg_fmt = shift
        or die "Must provide a test message format as argument";

    my %was_called;
    my $cb_sub = sub {
        my $event = shift;
        $was_called{ $event->{name} } = 1;
        return 1;
    };

    my $check_sub = sub {
        ok( ( 0 == grep { ! $_ } map { delete $was_called{$_} } @_ ),
            sprintf $msg_fmt, join ',', @_ );
    };
    return ($cb_sub, $check_sub);
}

$alpm_opt{ignorepkgs} = [ 'baz' ];

my ($event_log, $event_check)
    = create_cb_checker( 'events (%s) were fired' );
my ($conv_log,  $conv_check)
    = create_cb_checker( 'questions (%s) were asked' );
my ($progress_log, $progress_check)
    = create_cb_checker( 'progress (%s) was reported' );

my $trans = ALPM->transaction( type     => 'sync',
                               event    => $event_log,
                               progress => $progress_log,
                               conv     => $conv_log );
$trans->add( 'baz' );
$conv_check->( 'install_ignore' );
$trans->commit;
$progress_check->( 'add' );
undef $trans;

sub dump_log
{
    my $event = shift;
    print STDERR Dumper( $event ), "\n";

}

$alpm_opt{ignorepkgs} = [ ];

diag "Testing sysupgrade and replacing packages";

TODO:
{
    local $TODO = 'Cannot get package replacing to work';
    $trans = ALPM->transaction( type     => 'sysupgrade',
                                conv     => $conv_log );
    $trans->prepare;
    eval { $trans->commit; };
    $conv_check->( "replace_package" );

    undef $trans;
}
