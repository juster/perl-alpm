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

    eval {
        $trans->prepare;
        if ( $self->{'opts'}{'print'} ) {
            $self->_print_targets;
            return 0;
        }

        return 1 unless $self->trans_confirm( $trans );

        $trans->commit;
    };
    if ( $EVAL_ERROR ) {
        my $err = $trans->{'error'} or die;
        $self->_print_trans_err( $err );
    }

    return 0;
}

# Params : @questions - Questions to concatenate and print together.
# Returns: The answer! (sans newline)
sub prompt_ask
{
    my $self = shift;

    my $question = join q{}, @_;
    chomp $question;
    $question .= q{ };

    local $OUTPUT_AUTOFLUSH = 1;
    print $question;

    my $line = <STDIN>;
    chomp $line;
    return $line;
}

# Params: $question - Yes or no question to ask user.
#         $default  - Whether 'yes' or 'no' is the default.
#                     (default for $default is Yes!)
# Returns: 1 for yes 0 for no
sub prompt_yn
{
    my $self = shift;
    
    my ($question, $default) = @_;
    $default ||= 'y';

    my $first = lc substr $default, 0, 1;
    $default = ( $first eq 'y' ? 1 : $first eq 'n' ? 0 : 1 );

    chomp $question;
    $question .= q{ } . ( $default ? '[Y/n]' : '[y/N]' );

    my $answer;
    QUESTION: {
        $answer = $self->prompt_ask( $question );
        return $default if ( length $answer == 0 );
        redo QUESTION unless $answer =~ /\A[yYnN]/;
    }

    return 0 if $answer =~ /\A[nN]/;
    return 1;
}

sub _display_packages
{
    my ($self, $prefix, @pkgs) = @_;

    my $makedesc = ( $self->{cfg}{showsize}
                     ? sub {
                         sprintf '%s-%s [%.2f MB]',
                             ( $_->name, $_->version,
                               $_->size / ( 1024 * 1024 ) );
                     }
                     : sub {
                         sprintf '%s-%s', ( $_->name, $_->version );
                     } );

    $prefix .= q{ };
    my $LINE_MAX = 78 - length $prefix;

    my (@lines, $line);

    for my $desc ( map { $makedesc->() } @pkgs ) {
        if ( length $line + length $desc + 2 > $LINE_MAX ) {
            push @lines, $line;
            $line = $desc;
            next;
        }

        $line .= q{  } . $desc;
    }
    push @lines, $line;

    my $indent = q{ } x ( length $prefix ) + 1;
    my $output = join "\n", ( $prefix . ( shift @lines ),
                              map { $indent . $_ } @lines );
    return $output . "\n";
}

sub display_removals
{
    my ($self, $trans) = @_;

    my @removals = $trans->get_removals();
    my $title = sprintf 'Remove (%d):', scalar @removals;
    $self->_display_packages( $title, @removals );

    my $isize;
    for my $pkg ( @removals ) {
        $isize  += $pkg->isize;
    }

    printf "\nTotal Removed Size:   %.2f MB\n", $isize / ( 1024 * 1024 );

    return;
}

sub display_additions
{
    my ($self, $trans) = @_;

    my @additions = $trans->get_additions();
    my $title = sprintf 'Targets (%d):', scalar @additions;
    $self->_display_packages( $title, @additions );

    my ($dlsize, $isize);
    for my $pkg ( @additions ) {
        $dlsize += $pkg->download_size;
        $isize  += $pkg->isize;
    }

    printf "\nTotal Download Size:    %.2f MB\n",
        $dlsize / ( 1024 * 1024 );

    unless ( $self->{'opts'}{'dlonly'} ) {
        printf "Total Installed Size:   %.2f MB\n",
            $dlsize / ( 1024 * 1024 );
    }
}

sub _check_root
{
    my ($self) = @_;

    # We don't need root privileges if we are only going to print...
    return if $self->{'opts'}{'print'};

    return if $EFFECTIVE_USER_ID == 0;
    $self->fatal( 'you cannot perform this operation unless you are root.' );
}

sub _print_targets
{
    my ($self, $pkgs_ref) = @_;

    my $format = $self->{'opts'}{'print-format'} || '%l';

    for my $pkg ( @{ $pkgs_ref } ) {
        my $line = $format;
        $line =~ s/\%n/ $pkg->name /ge;
        $line =~ s/\%v/ $pkg->version /ge;
        $line =~ s/\%l/ $self->_get_pkg_loc( $pkg ) /ge;
        $line =~ s/\%r/ ( $pkg->db ? $pkg->db->name : 'local' ) /ge;
        $line =~ s{\%s}{ sprintf '%.2f', $pkg->size / ( 1024**2 ) }ge;
        print $line, "\n";
    }

    return;
}

sub _get_pkg_loc
{
    my ($self, $pkg_obj) = @_;

    my $method = $self->{'trans_method'};

    if ( $method eq 'sync' ) {
        my $dburl = $pkg_obj->db->url or return $pkg_obj->filename;
        return sprintf '%s/%s', $dburl, $pkg_obj->filename;
    }
    elsif ( $method eq 'upgrade' ) {
        return $pkg_obj->filename;
    }

    return sprintf '%s-%s', $pkg_obj->name, $pkg_obj->version;
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

sub _print_invalid_arch_err
{
    my ($self, $pkgname) = @_;

    print ":: package $pkgname does not have a valid architecure\n";
}

1;
