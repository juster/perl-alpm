package ALPM::Transaction;

use warnings;
use strict;
use Carp qw(carp croak);

# This is just a simple class method used to store the settings
# used to create the transaction and associate the hashref with
# this package.  Most of the functionality is in ALPM.xs.

sub new
{
    my $class = shift;

    my %trans_opts = @_;

    bless { prepared => 0,
            flags    => $trans_opts{flags},
            event    => $trans_opts{event},
           }, $class;
}

sub get_flags
{
    my ($self) = @_;

    my @flag_names;
    my $raw_flags = _trans_get_flags();
    FLAG_CHECK:
    while ( my ($flagname, $flagmask) = each %ALPM::_TRANS_FLAGS ) {
        next FLAG_CHECK unless $raw_flags & $flagmask;
        push @flag_names, $flagname;
    }

    return wantarray ? @flag_names : join q{ }, @flag_names;
}

sub get_additions
{
    my ($self) = @_;
    return @{ _trans_get_add() };
}

sub get_removals
{
    my ($self) = @_;
    return @{ _trans_get_remove() };
}

1;

__END__

=head1 NAME

ALPM::Transaction - An object wrapper for transaction functions.

=head1 SYNOPSIS

  my $t = ALPM->transaction( flags => 'nodeps force',
                             event => sub { ... },
                             conv  => sub { ... },
                             progress => sub { ... },
                            );
  $t->sync( $_ ) for qw/ perl perl-alpm /;
  eval { $t->commit };
  if ( $EVAL_ERROR ) {
      die unless $t->{error}; # re-throw an unknown error
      given ( $t->{error}{type} ) {
          when ( 'fileconflict' ) {
              for my $path ( @{ $t->{error}{list} } ) {
                  say "Conflicting Path: $path";
              }
          }
          when ( 'invalid_package' ) {
              say "Corrupt Package: $_" foreach ( @{ $t->{error}{list} } );
          }
      }
  }

=head1 DESCRIPTION

The transaction object wraps all the C<alpm_trans_...> C functions.
When the object goes out of scope and is automatically garbage
collected, the transaction is released.

=head1 METHODS

=head2 sync

C<< $TRUE = $TRANS->sync( $PKGNAME ); >>

Sync adds a package to synchronize via the database repos.  The
package from the database repository is downloaded and installed.

=head3 Parameters

=over

=item C<$PKGNAME>

The name of a package.

=back

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 pkgfile

C<< $TRUE = $TRANS->pkgfile( $PKGPATH ); >>

Adds a package file to be installed by the transaction.

=head3 Parameters

=over

=item C<$PKGPATH>

The path to the package file to install.

=back

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 remove

C<< $TRUE = $TRANS->remove( $PKGNAME ); >>

Adds a package to be removed/uninstalled by the transaction.

=head3 Parameters

=over

=item C<$PKGNAME>

The name of a package.

=back

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 sync_from_db

C<< $TRUE = $TRANS->sync_from_db( $DBNAME, $PKGNAME ); >>

Sync a package from the specified database.

=head3 Parameters

=over

=item C<$DBNAME>

The name of the database.

=item C<$PKGNAME>

The name of a package.

=back

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 sysupgrade

C<< $TRUE = $TRANS->sysupgrade( [$ENABLE_DOWNGRADE] ); >>

Prepares a transaction for the actions it needs to perform
a system upgrade.  A system upgrade will sync all the packages
that are outdated in the local database.

=head3 Parameters

=over

=item C<$ENABLE_DOWNGRADE>

Whether to allow downgrading of packages.  If the version installed is
greated than the version on the remote database, than the local
version installed will still be replaced.

Supply any argument in order to enable downgrading.  The value of the
argument is not checked.  Do not supply an argument if you do
not wish to enable downgrading.

=back

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 get_flags

C<< $FLAGSTR|@FLAGLIST = $TRANS->get_flags(); >>

Returns a list or string representing the flags specified when
creating the transaction with L<ALPM/transaction>.

=head3 Parameters

I<None>

=head3 Returns

=over

=item C<$FLAGSTR>

A string similar to the one used when creating the transaction.  The
flags may be in a different order than originally passed to the
L<ALPM/transaction> method.  This string is returned in
scalar context.

=item C<@FLAGLIST>

A list of strings with each representing a flag.  This list is
returned when in list context.

=back

=head2 prepare

C<< $TRUE = $TRANS->prepare() >>

Prepares a transaction.  The transaction will be checked for problems
and could even throw an error.

L</commit> checks if a transaction is prepared.  If not
it calls this C<prepare> method automatically.

=head3 Parameters

I<None>

=head3 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 commit

C<< $TRUE = $TRANS->commit(); >>

Commits the transaction.  Actually performs the actions loaded into
the transaction.

=head2 Parameters

I<None>

=head2 Returns

=over

=item C<$TRUE>

The literal: 1

=back

=head2 get_additions

C<< @PKGS = $TRANS->get_additions(); >>

This method will return a list of packages that are going to be
installed by the transaction.

=head3 Parameters

I<None>

=head3 Returns

=over

=item C<@PKGS>

A list of L<ALPM::Package> objects.

=back

=head2 get_removals

C<< @PKGS = $TRANS->get_removals(); >>

This method will return a list of packages that are going to be
uninstalled by the transaction.

=head3 Parameters

I<None>

=head3 Returns

=over

=item C<@PKGS>

A list of L<ALPM::Package> objects.

=back

=head1 RELEASING A TRANSACTION

You may have noticed there is no release method.  A transaction is
released as soon as it goes out of scope and is garbage collected.
For example:

  sub foo
  {
      my $t = ALPM->transaction();
      ... do stuffs ...
  }

  # here, $t is out of scope, garbage collected, and transaction is
  # released

In this way, with good coding practices, you should not need to
release a transaction because it will go out of scope.  But in order to
explicitly release a transaction undefine it.  For example:

  my $t = ALPM->transaction();
  $t->sync('perl');
  $t->commit;
  undef $t;

  # or
  $t = undef;

  # Transaction is released immediately

So be careful you don't keep extra copies of a transaction stored
around or else it will not be released.  If you need extra copies
try using C<weaken> in L<Scalar::Util>.

=head2 DOUBLE TRANSACTION PROBLEM

A problem can occur if you are trying to replace a transaction
stored in a scalar with a new transaction:

  my $t = ALPM->transaction();
  $t->sync( 'perl' );
  $t->commit();
  $t = ALPM->transaction();  # THIS WILL FAIL!

The problem is the C<$t> is not I<undefined> and released until after
the C<<ALPM->transaction()>> call is finished.  Unfortunately the method
cannot work because the previous transaction in C<$t> is not released
yet!  Catch 22!  You will have to explicitly C<undef> the transaction
in this case:

  my $t = ALPM->transaction();
  $t->sync( 'perl' );
  $t->commit;
  undef $t; # force release!
  $t = ALPM->transaction();

=head1 EVENT CALLBACKS

The C<ALPM::transaction()> method takes an optional event key/value
pair.  The event types and their different values are listed here
because there are so many of them.

Events are passed to the callback as a hash reference.  Every event
type has a C<name> and a C<status> key.  The name gives the type of
event, and status gives a string representing the status.  The
different kinds of extra arguments depends on the type of event.

All events can have one of the two statuses, 'start' or 'done' unless
noted.

=over

=item B<checkdeps>

=item B<fileconflicts>

=item B<resolvedeps>

=item B<integrity>

=item B<deltaintegrity>

All the above events have no special keys.

=item B<interconflicts>

When status is 'done' there is a key named 'target' which is an
L<ALPM::Package> object.

=item B<add>

Both 'start' and 'done' events also have a key named 'package' which
is an L<ALPM::Package> object.

=item B<remove>

Both 'start' and 'done' events also have a key named 'package' which
is an L<ALPM::Package> object.

=item B<upgrade>

The 'start' event has a key named 'package'.  The 'done' event has the
keys 'new' and 'old'.

=item B<deltapatches>

The 'done' event also has keys 'pkgname', and 'patches'.

=item B<deltapatch>

There is also a fail event with 'status' set to 'failed', in which case
there is an 'error' key with an error message as its value.

=item B<scriptlet>

This always has 'status' set to the empty string.  There is also a
'text' key with the scriptlet text I imagine?

=item B<printuri>

This always has 'status' set to the empty string.  There is also a
'name' key with the URI I guess?

=item B<retrieve>

This always has 'status' set to 'start'.  There is also a 'db'
key which has the name (ex: "extra") of the database where the
package is being retrieved from.


=back

=head1 CONVERSATION CALLBACKS

The conversation callback lets ALPM ask questions to the user.  The
question is passed as a hash reference.  The callback returns 1 to
answer yes, 0 to answer no. Each key of the hashref is described
below.

=over 4

=item B<id>

The integer value of the callback type.  It is one of these constants,
which are exported from ALPM as functions by request:

=over 4

=item PM_TRANS_CONV_INSTALL_IGNOREPKG

=item PM_TRANS_CONV_REPLACE_PKG

=item PM_TRANS_CONV_CONFLICT_PKG

=item PM_TRANS_CONV_CORRUPTED_PKG

=back

=item B<name>

Ids are converted to string names.  Each decides what other arguments
are provided in the hash reference.

=back

The following table shows what arguments are given for each named
conversation event as well as the purpose of each named event.
Arguments are simply additional keys in the hash ref.

  |------------------+------------------------------------------------|
  | Name             | Description                                    |
  |------------------+------------------------------------------------|
  | install_ignore   | Should the package be installed or ignored?    |
  | - package        | The package, an ALPM::Package object.          |
  |------------------+------------------------------------------------|
  | replace_package  | Should the old package be replaced by another? |
  | - old            | The old package, an ALPM::Package object.      |
  | - new            | The new package, an ALPM::Package object.      |
  | - db             | The name of the database's repository.         |
  |------------------+------------------------------------------------|
  | package_conflict | Should the conflicting package be removed?     |
  | - target         | The name of the package being conflicted.      |
  | - local          | The name of the removable local package.       |
  | - conflict       | The type/name of the conflict.                 |
  |------------------+------------------------------------------------|
  | corrupted_file   | Should the corrupted package file be deleted?  |
  | - filename       | The name of the corrupted package file.        |
  |------------------+------------------------------------------------|

=head1 PROGRESS CALLBACKS

Progress of the transaction can be reported to a progress callback.
Progress is reported as a hash reference, again.  The keys are
described in the following table:

  |-------------+-----------------------------------------------------|
  | Name        | Description                                         |
  |-------------+-----------------------------------------------------|
  | id          | The numeric ID of the progress type.  Can be:       |
  |             | - PM_TRANS_PROGRESS_ADD_START                       |
  |             | - PM_TRANS_PROGRESS_UPGRADE_START                   |
  |             | - PM_TRANS_PROGRESS_REMOVE_START                    |
  |             | - PM_TRANS_PROGRESS_CONFLICTS_START                 |
  |-------------+-----------------------------------------------------|
  | name        | The string conversion of the numeric ID:            |
  |             | - add                                               |
  |             | - upgrade                                           |
  |             | - remove                                            |
  |             | - conflicts                                         |
  |-------------+-----------------------------------------------------|
  | desc        | A string for extra description of the callback.     |
  |             | For example, the name of the package being added.   |
  |-------------+-----------------------------------------------------|
  | item        | The percentage of progress for the individual item. |
  |             | Like a package, for example.                        |
  |-------------+-----------------------------------------------------|
  | total_count | The number of items being processed in total.       |
  |-------------+-----------------------------------------------------|
  | total_pos   | The item's position in the total count above.       |
  |-------------+-----------------------------------------------------|

=head1 ERRORS

Transaction errors are croaked and can be examined with the C<$@> or
C<$EVAL_ERROR> variable like other ALPM errors.  They are prefixed
with B<ALPM Transaction Error:>.  Errors can happen when preparing or
commiting.

Extra information is available for ALPM transaction errors.  When an
error occurs the transaction object that was used will have a new hash
key called I<error>, containing a hash reference.

The I<error> hash reference has the keys I<msg>, I<list>, and I<type>.
I<msg> is the same as the string in C<$@>, without the B<ALPM
Transaction Error:> prefix.  The array ref in I<list> is different
depending on each type.  Each I<type> and its associated I<msg> and
I<list> are described in the following table.

  |-----------------+--------------------------------------------------|
  | Type            | Description                                      |
  |-----------------+--------------------------------------------------|
  | fileconflict    | Two packages share a file with the same path.    |
  | - msg           | 'conflicting files'                              |
  | - list          | An arrayref of hashes representing the conflict: |
  | -- target       | The package which caused the conflict.           |
  | -- type         | 'filesystem' or 'target'                         |
  | -- file         | The path of the conflicting file.                |
  | -- ctarget      | Empty string ('') ?                              |
  |-----------------+--------------------------------------------------|
  | depmissing      | A dependency could not be satisfied (missing?).  |
  | - msg           | 'could not satisfy dependencies'                 |
  | - list          | An arrayref of hashes represending the dep:      |
  | -- target       | The depended on package name.                    |
  | -- cause        | The package name of who depends on target.       |
  | -- depend       | A hashref, same as dependencies of packages.     |
  |-----------------+--------------------------------------------------|
  | depconflict     | A package which explicitly conflicts with        |
  |                 | another (in the PKGBUILD) cannot be installed.   |
  | - msg           | 'conflicting dependencies'                       |
  | - list          | An arrayref of hashrefs showing the conflict:    |
  | -- reason       | A reason message.                                |
  | -- packages     | An arrayref of two packages who conflict.        |
  |-----------------+--------------------------------------------------|
  | invalid_delta   | (UNTESTED) A delta is corrupted?                 |
  | - msg           | ?                                                |
  | - list          | An arrayref of corrupted delta names.            |
  |-----------------+--------------------------------------------------|
  | invalid_package | A package is corrupted (or invalid?).            |
  | - msg           | 'invalid or corrupted package'                   |
  | - list          | An arrayref of package filenames.                |
  |-----------------+--------------------------------------------------|

=head1 SEE ALSO

L<ALPM>

=head1 AUTHOR

Justin Davis, C<< <juster at cpan dot org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
