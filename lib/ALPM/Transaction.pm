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
            type     => $trans_opts{type},
            flags    => $trans_opts{flags},
            event    => $trans_opts{event} }, $class;
}

sub add
{
    my $self = shift;

    # Transaction state gets messed up if we don't catch this...
    croak 'ALPM Error: cannot add to a prepared transaction'
        if ( $self->{prepared} );

    ADD_LOOP:
    for my $pkgname ( @_ ) {
        if ( ref $pkgname ) {
            carp 'target cannot be a reference, ignored';
            next ADD_LOOP;
        }

        # Provide line numbers of calling script if an error occurred.
        eval { alpm_trans_addtarget($pkgname); };
        if ( $@ ) {
            die "$@\n" unless ( $@ =~ /\AALPM Error:/ );

            $@ =~ s/ at .*? line \d+[.]\n//;
            croak $@;
        }
    }

    return 1;
}

1;

__END__

=head1 NAME

ALPM::Transaction - An object wrapper for transaction functions.

=head1 SYNOPSIS

  my $t = ALPM->transaction( type  => 'upgrade',
                             flags => 'nodeps force' );
  $t->add( qw/ perl perl-alpm / );
  $t->commit;

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
explicitly release a transaction, assign C<undef> to it.  For example:

  my $t = ALPM->transaction( type => 'sync' );
  $t->add('perl');
  $t->commit;
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

=head1 SEE ALSO

L<ALPM>

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
