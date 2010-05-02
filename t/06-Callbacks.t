#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 11;
use ALPM qw(t/test.conf);
use File::Spec::Functions qw(rel2abs);
use File::stat qw(stat);
use File::Copy qw(copy);
use File::Basename;
use Cwd;

my $log_lines = q{};
tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = sub { $log_lines .= $_[1] };

my $db = ALPM->register( 'simpletest' => rel2abs('t/repos/share/simpletest') );
my $foopkg = $db->find('foo');

ok( length $log_lines > 0 );
ok( $foopkg );

$alpm_opt{logcb} = undef;

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

# use Data::Dumper;
# sub dump_cb {
#     print STDERR Dumper(\@_);
# }

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

my $trans = ALPM->transaction( type     => 'sync',
                               event    => $event_log,
                               progress => $progress_log,
                               conv     => $conv_log );
$trans->add( 'baz' );
$conv_check->( 'install_ignore' );
$trans->commit;
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

ok( ALPM->unregister_all_dbs );
ok( ALPM->register( 'local' ) );

ok( $db = ALPM->register( 'upgradetest',
                          rel2abs( 't/repos/share/upgradetest' )) );
ok( $db->update );

$trans = ALPM->transaction( type => 'sysupgrade',
                            conv => $conv_log );
eval { $trans->commit };
$conv_check->( 'replace_package' );

undef $trans;

ok( $copied_files, 'Fetch callback worked' );



