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
    print STDERR join q{ }, 'LOG', sprintf('[%s]', $lvl), $msg;
}

tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = \&print_log;

my $db = ALPM->register( 'simpletest' => rel2abs('t/repos/share') );
my $foopkg = $db->find('foo');

ok( length $log_lines );

#$alpm_opt{logcb} = undef;

my (%event_is_done, %conv_was_asked);

sub event_log
{
    my ($event) = @_;

    return unless ( $event->{status} eq 'done' );
    my $name = $event->{name};
    $event_is_done{ $name } = 1;
}

sub check_events
{
    ok( ( 0 == grep { ! $_ } map { delete $event_is_done{$_} } @_ ),
        sprintf 'transaction events (%s) are done', join ',', @_ );
}

sub conv_log
{
    my $conv = shift;

    use Devel::Peek;
    Dump($conv);

    if ( $conv->{name} eq 'install_ignore' ) {
        print STDERR "Package: ", $conv->{package}->name, "\n";
    }

    $conv_was_asked{ $conv->{name} } = 1;
    return 1;
}

sub check_conv
{
    ok( ( 0 == grep { ! $_ } map { delete $conv_was_asked{$_} } @_ ),
        sprintf 'transaction conv (%s) was asked', join ',', @_ );
}

$alpm_opt{ignorepkgs} = [ 'baz' ];

my $trans = ALPM->transaction( type  => 'sync',
                               event => \&event_log,
                               conv  => \&conv_log );
$trans->add( 'baz' );
check_conv( "install_ignore" );
$trans->commit;
undef $trans;

$trans = ALPM->transaction( type => 'sync',
                            conv => \&conv_log );
$trans->add( 'replacebaz' );
check_conv( "replace_package" );
$trans->commit;
undef $trans;
