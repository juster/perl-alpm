package ALPM::Transaction;

use warnings;
use strict;
use Carp qw(carp croak);

sub new
{
    my $class = shift;

    my %trans_opts = @_;

    return bless { prepared => 0,
                   type     => $trans_opts{type},
                   flags    => $trans_opts{flags} }, $class;

}

sub add
{
    my $self = shift;

#     croak 'ALPM Error: cannot add targets to a prepared transaction'
#         if ( $self->{prepared} );

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
                             flags => qw/ nodeps force / );
  $t->add( qw/ perl perl-alpm / );
  $t->commit;

=head1 DESCRIPTION

The transaction object wraps all the C<alpm_trans_...> C functions.
When the object goes out of scope and is automatically garbage
collected, the transaction is released.

=head1 METHODS

=head2 add

  Usage    : $trans->add( 'perl', 'perl-alpm', 'etc' );
  Purpose  : Add package names to be affected by transaction.
  Params   : A list of package names to be added.
  Returns  : 1

=head2 prepare

=head2 commit

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
