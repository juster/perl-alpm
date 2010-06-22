package ALPM::Transaction;

use warnings;
use strict;
use Carp qw(carp croak);

# This is just a simple class method used to store the settings
# used to create the transaction and associate the hashref with
# this package.  Most of the functionality is in ALPM.xs.

my %IS_VALID_TYPE = map { ( $_ => 1 ) } qw/ sync upgrade remove /;

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
  $t->upgrade( qw/ perl perl-alpm / );
  eval { $t->commit };
  if ( $EVAL_ERROR ) {
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

=head2 add

  Usage   : $trans->add( 'perl', 'perl-alpm', 'etc' );
  Purpose : Add package names to be affected by transaction.
  Params  : A list of package names to be added (or just one).
  Comment : You cannot add packages to a prepared transaction.
  Returns : 1

=head2 prepare

  Usage   : $trans->prepare;
  Purpose : Prepares a transaction for committing.
  Comment : commit() does this automatically if needed.
  Returns : 1

=head2 commit

  Usage   : $trans->commit;
  Purpose : Commits the transaction.
  Returns : 1

=head1 RELEASING A TRANSACTION

You may have noticed there is no release method.  A transaction is
released as soon as it goes out of scope and is garbage collected.
For example:

  sub foo
  {
      my $t = ALPM->transaction( type => 'sync' );
      ... do stuffs ...
  }

  # here, $t is out of scope, garbage collected, and transaction is
  # released

In this way, with good coding practices, you should not need to
release a transaction because it will go out of scope.  But in order to
explicitly release a transaction undefine it.  For example:

  my $t = ALPM->transaction( type => 'sync' );
  $t->add('perl');
  $t->commit;
  undef $t;

  # or
  $t = undef;

  # Transaction is released immediately

So be careful you don't keep extra copies of a transaction stored
around or else it will not be released.  If you need extra copies
try using C<weaken> in L<Scalar::Util>.

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

  |------------------+---------------------------------------------------|
  | Name             | Description                                       |
  |------------------+---------------------------------------------------|
  | install_ignore   | Should the package be installed, and not ignored? |
  | - package        | The package in question, an ALPM::Package object. |
  |------------------+---------------------------------------------------|
  | replace_package  | Should the old package be replaced by another?    |
  | - old            | The old package, an ALPM::Package object.         |
  | - new            | The new package, an ALPM::Package object.         |
  | - db             | The name of the database's repository.            |
  |------------------+---------------------------------------------------|
  | package_conflict | Should the conflicting package be removed?        |
  | - package        | The name of the package being conflicted.         |
  | - removable      | The name of the removable package.                |
  |------------------+---------------------------------------------------|
  | corrupted_file   | Should the corrupted package file be deleted?     |
  | - filename       | The name of the corrupted package file.           |
  |------------------+---------------------------------------------------|

=back

=head1 PROGRESS CALLBACKS

Progress of the transaction can be reported to a progress callback.
Progress is reported as a hash reference, again.  The keys are
described in the following table:

  |-------------+------------------------------------------------------|
  | Name        | Description                                          |
  |-------------+------------------------------------------------------|
  | id          | The numeric ID of the progress type.  Can be one of: |
  |             | - PM_TRANS_PROGRESS_ADD_START                        |
  |             | - PM_TRANS_PROGRESS_UPGRADE_START                    |
  |             | - PM_TRANS_PROGRESS_REMOVE_START                     |
  |             | - PM_TRANS_PROGRESS_CONFLICTS_START                  |
  |-------------+------------------------------------------------------|
  | name        | The string conversion of the numeric ID:             |
  |             | - add                                                |
  |             | - upgrade                                            |
  |             | - remove                                             |
  |             | - conflicts                                          |
  |-------------+------------------------------------------------------|
  | desc        | A string for extra description of the callback.      |
  |             | For example, the name of the package being added.    |
  |-------------+------------------------------------------------------|
  | item        | The percentage of progress for the individual item.  |
  |             | Like a package, for example.                         |
  |-------------+------------------------------------------------------|
  | total_count | The number of items being processed in total.        |
  |-------------+------------------------------------------------------|
  | total_pos   | The item's position in the total count above.        |
  |-------------+------------------------------------------------------|

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

  |-----------------+------------------------------------------------------|
  | Type            | Description                                          |
  |-----------------+------------------------------------------------------|
  | fileconflict    | More than one package has a file with the same path. |
  | - msg           | 'conflicting files'                                  |
  | - list          | An arrayref of hashes representing the conflict:     |
  | -- target       | The package which caused the conflict.               |
  | -- type         | 'filesystem' or 'target'                             |
  | -- file         | The path of the conflicting file.                    |
  | -- ctarget      | Empty string ('') ?                                  |
  |-----------------+------------------------------------------------------|
  | depmissing      | A dependency could not be satisfied (missing?).      |
  | - msg           | 'could not satisfy dependencies'                     |
  | - list          | An arrayref of hashes represending the dep:          |
  | -- target       | The depended on package name.                        |
  | -- cause        | The package name of who depends on target.           |
  | -- depend       | A hashref, same as dependencies of package objects.  |
  |-----------------+------------------------------------------------------|
  | depconflict     | A package which explicitly conflicts with another    |
  |                 | (in the PKGBUILD) cannot be installed.               |
  | - msg           | 'conflicting dependencies'                           |
  | - list          | An arrayref of hashrefs showing the conflict:        |
  | -- reason       | A reason message.                                    |
  | -- packages     | An arrayref of two packages who conflict.            |
  |-----------------+------------------------------------------------------|
  | invalid_delta   | (UNTESTED) A delta is corrupted?                     |
  | - msg           | ?                                                    |
  | - list          | An arrayref of corrupted delta names.                |
  |-----------------+------------------------------------------------------|
  | invalid_package | A package is corrupted (or invalid?).                |
  | - msg           | 'invalid or corrupted package'                       |
  | - list          | An arrayref of package filenames.                    |
  |-----------------+------------------------------------------------------|

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
