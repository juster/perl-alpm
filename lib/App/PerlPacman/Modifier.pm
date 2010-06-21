package App::PerlPacman::Modifier;

use warnings;
use strict;

use App::PerlPacman;
our @ISA = qw( App::PerlPacman );

sub new
{
    my $class        = shift;
    my $trans_method = shift;
    
    my $self                  = $class->SUPER::new( @_ );
    $self->{ 'trans_method' } = $trans_method;
    return $self;
}

my %FLAG_OF_OPT =
    # Some options are exactly the same as their transaction option...
    map { ( $_ => $_ ) } qw{ nodeps force nosave cascade dbonly
                             noscriptlet needed unneeded },
    ( 'asdeps' => 'alldeps', 'asexplicit' => 'allexplicit',
      'downloadonly' => 'dlonly', 'print' => 'printuris',
     );

=for Missing Transaction Flags
Other transaction flags which aren't included are:
  recurse & recurseall - if the recursive flag is given once, we
    use the 'recurse' trans flag.  if given twice we use 'recurseall'.
  noconflicts - I'm not sure which option this corresponds to

=cut

#---PRIVATE METHOD---
# Converts options to a string of transaction flags.
# It is the subclasses' responsibility to parse the options
# that is recognizes...
sub _convert_trans_opts
{
    my ($self) = @_;

    my $opts = $self->{'opts'};
    my @trans_flags = ( grep { defined }
                        map  { $FLAG_OF_OPT{ $_ } }
                        keys %$opts );

    my $recursive = $opts->{'recursive'};
    REC_CHECK:
    {
        last REC_CHECK unless $recursive && eval { $recursive =~ /\A\d\z/ };
        if    ( $recursive == 1 ) { push @trans_flags, 'recurse';    }
        elsif ( $recursive >  1 ) { push @trans_flags, 'recurseall'; }
    }

    return @trans_flags ? join q{ }, @trans_flags : q{};
}

sub transaction
{
    my ($self) = @_;

    my $flags = $self->_convert_trans_opts();
    my $trans = ALPM->transaction( 'flags' => $flags );
    # TODO: create the proper callbacks to match pacman's output...

    return $trans;
}

# This is so common, we place it here in the superclass...
# We run a transaction, calling the given method on the transaction object
# for each argument we are passed on the command-line...
sub run_transaction
{
    my ($self, $method_name) = @_;

    my $trans = $self->transaction();
    my $method = $ALPM::Transaction::{ $method_name }{CODE};

    for my $pkgname ( $self->{'extra_args'} ) {
        $method->( $trans, $pkgname );
    }

    return 0;
}

1;
