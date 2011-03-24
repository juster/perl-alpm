#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 32;

use File::Spec::Functions qw(rel2abs);
use ALPM qw(t/test.conf);

$ENV{'LANGUAGE'} = 'en_US';

# TRANSACTION ERRORS

tie my %alpm_opt, 'ALPM';
$alpm_opt{logcb} = sub { printf '[%8s] %s', @_ };

ALPM->register( 'simpletest' => rel2abs('t/repos/share/simpletest') );

# File Conflict Error ########################################################

my $t = ALPM->trans();
ok( $t->sync( 'fileconflict' ) );
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

$t = ALPM->trans();
ok( $t->remove( 'foo' ));
eval { $t->prepare };
ok( $@ =~ /^ALPM Transaction Error:/
    && $t->{error}, 'A transaction error occurred' );

is $t->{error}{type}, 'depmissing';
($error) = @{$t->{error}{list}};
is scalar @{$t->{error}{list}}, 1;
is $t->{error}{msg}, 'could not satisfy dependencies';

is $error->{target}, 'bar';
is $error->{depend}{name}, 'foo';
is $error->{cause}, 'foo';
undef $t;

# Conflicting Dependencies ###################################################

$t = ALPM->trans();
ok( $t->sync( 'depconflict' ));
eval { $t->prepare };
ok( $@ =~ /^ALPM Transaction Error: conflicting dependencies/
    && $t->{error}, 'transaction error with conflicting deps' );

is $t->{error}{type}, 'conflict';
is $t->{error}{msg}, 'conflicting dependencies';
($error) = @{$t->{error}{list}};

is scalar @{$t->{error}{list}}, 1;
is $error->{packages}[0],'depconflict';
is $error->{packages}[1], 'foo';
is $error->{reason}, 'foo';
undef $t;

# Corrupt Packages ###########################################################

$t = ALPM->trans();
ok $t->sync( 'corruptme' );
ok $t->prepare;
eval { $t->commit };
like $@, qr/^ALPM Transaction Error: invalid or corrupted package/,
    'a corrupted package exception was raised';
is $t->{error}{type}, 'invalid_package';
is $t->{error}{msg}, 'invalid or corrupted package';
like $t->{error}{list}[0], qr/\Qcorruptme-1.0-1-any.pkg.tar.\E[gx]z/;
is scalar @{ $t->{error}{list} }, 1;

# Deltas ??? #################################################################

# I don't know much about them or how to test them yet.  But they are just
# a list of strings much like the above.
