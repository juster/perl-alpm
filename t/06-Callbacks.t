#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use ALPM qw(t/test.conf);
use File::Spec::Functions qw(rel2abs);
use File::stat qw(stat);
use File::Copy qw(copy);
use File::Basename;
use Cwd;

my $log_lines = q{};
tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = sub { $log_lines .= $_[1] };

my $db = ALPM->register( 'simpletest' => rel2abs('t/repos/share/simpletest'));
my $foopkg = $db->find('foo');

ok( length $log_lines > 0 );
ok( $foopkg );

$alpm_opt{logcb} = undef;

# Create two closures. One is used as a callback and records the
# name of every event fired. The other is used to check if
# an event of the given name was fired.
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
        my $testdesc = sprintf $msg_fmt, join ',', @_;
        ok( ( 0 == grep { ! $_ } map { delete $was_called{$_} } @_ ),
            $testdesc );
    };
    return ($cb_sub, $check_sub);
}

# $alpm_opt{'logcb'} = sub { printf STDERR '[%10s] %s', @_; };
$alpm_opt{'ignorepkgs'} = [ 'baz' ];

my ($total_bytes, $bytes_count);

$alpm_opt{dlcb} = sub {
    my ($fname, $trans, $total) = @_;
    $bytes_count += $total if ( $trans == $total );
};

$alpm_opt{totaldlcb} = sub {
    $total_bytes = $_[0] if ( $_[0] > 0 );
};

my ($event_log, $event_check)
    = create_cb_checker( 'events (%s) were fired' );
my ($conv_log,  $conv_check)
    = create_cb_checker( 'questions (%s) were asked' );
my ($progress_log, $progress_check)
    = create_cb_checker( 'progress (%s) was reported' );

my $trans = ALPM->trans( event    => $event_log,
                         progress => $progress_log,
                         conv     => $conv_log );

my @syncdbs = ALPM->syncdbs;
my $bazpkg  = ALPM->find_dbs_satisfier( \@syncdbs, 'baz' );
ok $bazpkg, 'found baz package';
$trans->install( $bazpkg );
$trans->prepare;
$trans->commit;
$conv_check->( 'install_ignore' );
$progress_check->( 'add' );
undef $trans;

ok( $total_bytes == $bytes_count,
    'Total download callback and download callbacks add up' );

delete $alpm_opt{dlcb};
delete $alpm_opt{totaldlcb};
delete $alpm_opt{ignorepkgs};

# Sysupgrade, replacement, fetch callback ####################################

#$alpm_opt{logcb} = sub { printf STDERR '[%8s] %s', @_ };

my $copied_files;
$alpm_opt{fetchcb} = sub {
    my ($fqp, $destdir) = @_;
    my $destfqp = $destdir . basename( $fqp );
    copy( $fqp, $destfqp ) or die "failed to copy $fqp: $!";
    $copied_files = 1;
    return stat($destfqp)->mtime;
};

$db->unregister for ALPM->syncdbs;

ok( $db = ALPM->register( 'upgradetest',
                          rel2abs( 't/repos/share/upgradetest' )),
    'register upgradetest test repository' );
ok( $db->update );

$trans = ALPM->trans( conv => $conv_log );
$trans->sysupgrade;
eval { $trans->commit };
$conv_check->( 'replace_package' );

undef $trans;

ok( $copied_files, 'Fetch callback worked' );
done_testing;
