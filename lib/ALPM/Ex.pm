package ALPM::Ex;

use warnings;
use strict;

use overload q{""} => \&message;

sub new
{
    my $class = shift;

    my ($msg, $conflicts) = @_;

    return bless { msg => $msg, conflicts => $errlist }, $class;
}

sub message
{
    my $self = shift;
    return $self->{msg};
}

sub conflicts
{
    my $self = shift;
    return @{$self->{conflicts}};
}

sub caught
{
    return eval { $@->isa( 'ALPM::Ex' ) };
}

1;

__END__

=head1 NAME

ALPM::Ex - An exception class that contains a list of conflicts.

=head1 SYNOPSIS

  use English qw(-no_match_vars);

  my $t = ALPM->transaction( type => 'update' );
  $t->add( qw/perl gcc bash/ );

  eval { $t->commit };
  if ( $EVAL_ERROR )
      die $EVAL_ERROR unless ALPM::Ex->caught;
      my $ex = $EVAL_ERROR;
      print "$ex\n", "Conflicting packages:\n",
          join( "\n", $ex->conflicts ), "\n";
  }

=head1 DESCRIPTION

Transaction methods can return a list of conflicts.  In case an error
happens an error message as well as the conflict list is thrown as an
ALPM::Ex object.

=head1 METHODS

=head2 message

This returns the ALPM error message.  This method is also used when
the object is used as a string.  The object is automatically
stringified.

=head2 conflicts

This returns a list of conflicts as package names.

=head1 SEE ALSO

L<ALPM::Transaction>

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

