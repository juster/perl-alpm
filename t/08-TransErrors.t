#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);

use File::Spec::Functions qw(rel2abs);
use ALPM qw(t/test.conf);

# TRANSACTION ERRORS

tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = sub { printf '[%8s] %s', @_ };

ALPM->register( 'simpletest' => rel2abs('t/repos/share/simpletest') );

# File Conflict Error ########################################################

my $t = ALPM->transaction( type => 'sync', );
ok( $t->add( 'fileconflict' ) );
eval { $t->commit };

ok( $@ && $t->{error}, 'A transaction error occurred' );
is( $t->{error}{type}, 'fileconflict', 'A file conflict occurred' );

# Copy the error, there's only one in the list.
is scalar @{$t->{error}{list}}, 1, 'Only one error occurred';
is $t->{error}{msg}, "conflicting files";
my ($error) = @{$t->{error}{list}};
is $error->{target}, 'fileconflict',
    q{The "fileconflict" package causes the file conflict, go figure!};
is $error->{type}, 'filesystem';
is $error->{file}, rel2abs('t/root/usr/foo/bar/baz');
is $error->{ctarget}, '';

undef $t;

# Unsatisfied dependencies ###################################################

$t = ALPM->transaction( type => 'remove', );
ok( $t->add( 'foo' ));
eval { $t->prepare };
ok( $@ =~ /^ALPM Transaction Error:/
    && $t->{error}, 'A transaction error occurred' );

is $t->{error}{type}, 'depmissing';
($error) = @{$t->{error}{list}};
is scalar @{$t->{error}{list}}, 1;
diag $t->{error}{msg};

is $error->{target}, 'bar';
is $error->{depend}{name}, 'foo';
is $error->{cause}, 'foo';
undef $t;

# Conflicting Dependencies ###################################################

$t = ALPM->transaction( type => 'sync' );
ok( $t->add( 'depconflict' ));
eval { $t->prepare };
ok( $@ =~ /^ALPM Transaction Error: conflicting dependencies/
    && $t->{error}, 'transaction error with conflicting deps' );

is $t->{error}{type}, 'conflict';
is $t->{error}{msg}, 'conflicting dependencies';
($error) = @{$t->{error}{list}};
is scalar @{$t->{error}{list}}, 1;
is $error->[0], 'depconflict';
is $error->[1], 'foo';
undef $t;

# Corrupt Packages ###########################################################

my $arch = `uname -m`;
chomp $arch;

$t = ALPM->transaction( type => 'sync' );
ok $t->add( 'corruptme' );
ok $t->prepare;
eval { $t->commit };
like $@, qr/^ALPM Transaction Error: invalid or corrupted package/,
    'a corrupted package exception was raised';
is $t->{error}{type}, 'invalid_package';
is $t->{error}{msg}, 'invalid or corrupted package';
is $t->{error}{list}[0], "corruptme-1.0-1-$arch.pkg.tar.gz";
is scalar @{ $t->{error}{list} }, 1;

# Deltas ??? #################################################################

# I don't know much about them or how to test them yet.  But they are just
# a list of strings much like the above.