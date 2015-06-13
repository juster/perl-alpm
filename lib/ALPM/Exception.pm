package ALPM::Exception v0.0.1;

use strict;
use warnings;

use ALPM;

use overload q{""} => sub { sprintf( "ALPM Error: %s.\n", $_[0]->strerror ); };

sub new {
    my ( $class, %args ) = @_;
    return bless \%args, $class;
}

sub throw {
    my ($self, @args) = @_;
    die ref $self ? $self : $self->new(@args);
}

sub strerror { return ALPM::Exception::alpm_strerror($_[0]->errno); }

1;

__END__

=head1 NAME

ALPM::Exception - base class for ALPM exceptions

=head1 SYNOPSIS

 ALPM::Exception->throw();

=head1 DESCRIPTION

=head2 Methods

All of the following methods may be called as either class or instance methods.

=over

=item throw

Throws the exception.

=item errno

If the exception represents one of libalpm's built-in errors C<errno> returns
the corresponding C<alpm_errno_t>.  Otherwise C<undef> is returned.

=item strerror

Returns the raw libalpm error string.

=back
