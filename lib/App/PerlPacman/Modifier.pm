package App::PerlPacman::Modifier;

use warnings;
use strict;
use English qw(-no_match_vars);

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
sub run
{
    my ($self) = @_;

    $self->_check_root;

    my @pkgnames = @{ $self->{ 'extra_args' } }
        or $self->fatal( 'no targets specified (use -h for help)' );

    my $method_name = $self->{'trans_method'}
        or die qq{INTERNAL ERROR: 'trans_method' is unset};
    my $trans = $self->transaction();
    my $method = $ALPM::Transaction::{ $method_name }
        or die qq{INTERNAL ERROR: invalid method name: $method_name};

    for my $pkgname ( @pkgnames ) {
        $method->( $trans, $pkgname );
    }

    eval { $trans->commit };
    if ( $EVAL_ERROR ) {
        my $err = $trans->{'error'} or die;
        $self->_print_trans_err( $err );
    }

    return 0;
}

sub _check_root
{
    my ($self) = @_;

    return if $EFFECTIVE_USER_ID == 0;
    $self->fatal( 'you cannot perform this operation unless you are root.' );
}

sub _print_depmissing_err
{
    my ($err) = @_;

    printf STDERR ":: %s: requires %s\n", $err->{'target'}, $err->{'cause'};
    return;
}

sub _print_trans_err
{
    my ($self, $error) = @_;

    $self->error( "failed to prepare transaction ($error->{msg})" );

    my $printer_name = "_print_$error->{type}_err";
    my $printer_ref  = $App::PerlPacman::Modifier::{ $printer_name }
        or die 'INTERNAL ERROR: no error printer available for '
            . $error->{'type'};

    for my $err ( @{ $error->{'list'} } ) {
        $printer_ref->( $err );
    }

    return;
}



1;
