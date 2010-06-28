package App::PerlPacman::Modifier;

use warnings;
use strict;
use English qw(-no_match_vars);

use App::PerlPacman;
our @ISA = qw( App::PerlPacman );

use Text::Wrap qw();

sub new
{
    my $class        = shift;
    my $trans_method = shift;
    
    my $self = $class->SUPER::new( @_ );

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
    my $trans = ALPM->transaction( 'flags' => $flags,
                                   'event' => $self->_trans_event_callback(),
                                  );
    # TODO: create the proper callbacks to match pacman's output...

    return $trans;
}

my %_EVENT_CALLBACKS =
    ( 'checkdeps'      => { 'start' => sub {
                                print "checking dependencies...\n";
                            } },
      'fileconflicts'  => { 'start' => sub {
                                print "checking for file conflicts...\n";
                            } },
      'resolvedeps'    => { 'start' => sub {
                                print "resolving dependencies...\n";
                            } },
      'interconflicts' => { 'start' => sub {
                                print "looking for inter-conflicts...\n";
                            } },
      'integrity'      => { 'start' => sub {
                                print "checking package integrity...\n";
                            } },
      'deltaintegrity' => { 'start' => sub {
                                print "checking delta integrity...\n";
                            } },
      'deltapatches'   => { 'start' => sub {
                                print "applying patches...\n";
                            } },
      'deltapatch'     => { 'start' => sub {
                                print "generating $_[0]{pkgname} with "
                                    . "$_[0]{patches}... ";
                            },
                            'done'  => sub {
                                print "success!\n";
                            },
                            'failed' => sub {
                                print "failed: $_[0]{error}\n";
                            },
                           },
      'scriptlet'      => sub { print $_[0]{'text'}; },
      'retrieve'       => { 'start' => sub {
                                print ":: Retrieving patches from "
                                    ."$_[0]{db}...\n";
                            } },
     );

sub _action_event_cb
{
    my ($self, $cb_ref, %params) = @_;
    my $type_ref;
    
    if ( $self->{'cfg'}{'noprogressbar'} ) {
        $type_ref->{'start'} = sub {
            print "$params{'verb'} %s...\n", $_[0]{'package'}->name;
        };
    }
    
    $type_ref->{'done'} = $params{'done'};

    $cb_ref->{ $params{'type'} } = $type_ref;
}

sub _trans_event_callback
{
    my ($self) = @_;

    my %callbacks = %_EVENT_CALLBACKS;

    my $done = sub {
        my $pkg =  $_[0]{'package'};
        $self->logaction( "installed %s (%s)\n",
                          $pkg->name, $pkg->version );
        $self->display_optdepends( $pkg );
    };
    $self->_action_event_cb( \%callbacks,
                             ( 'type' => 'add',
                               'verb' => 'installing',
                               'done' => $done ));
    $done = sub {
        my $pkg = $_[0]->{'package'};
        $self->logaction( "removed %s (%s)\n",
                          $pkg->name, $pkg->version );
    };
    $self->_action_event_cb( \%callbacks,
                             ( 'type' => 'remove',
                               'verb' => 'removing',
                               'done' => $done ));
    $done = sub {
        my ($new, $old) = @{$_[0]}{'new', 'old'};
        $self->logaction( "upgraded %s (%s -> %s)\n",
                          $new->name, $old->version, $new->version );
    };
    $self->_action_event_cb( \%callbacks,
                             ( 'type' => 'upgrade',
                               'verb' => 'upgrading',
                               'done' => $done ));
    return sub {
        my $event    = shift;
        my $callback = $callbacks{ $event->{'name'} }
            or return;

        if ( ref $callback eq 'HASH' ) {
            $callback = $callback->{ $event->{'status'} }
                or return;
        }

        $callback->( $event );
    };
}

sub _trans_converse_cb
{
    my ($self) = @_;

    my %converse_cb =
        ( 'install_ignore' => sub {
              my $pkg = shift->{'package'};
              my $msg = sprintf ':: %s is in IgnorePkg/IgnoreGroup. '
                  . ' Install anyway?', $pkg->name;
              $self->promptyn( $msg );
          },
          'replace_package' => sub {
              my ($old, $new, $db) = @{$_[0]}{'old', 'new', 'db'};
              $self->promptyn( ":: Replace $old with $db/$new?" );
          },
          'package_conflict' => sub {
              my ($target, $local, $conflict)
                  = @{$_[0]}{'target', 'local', 'conflict'};
              if ( ($target eq $local) || ($local eq $conflict) ) {
                  my $msg = ":: $target and $local are in conflict. "
                      . "Remove $local?";
                  return $self->promptny( $msg );
              }
              $self->promptny( ":: $target and $local are in conflict"
                               . " ($conflict). Remove $local?" );
          },
          'remove_packages' => sub {
              my @pkgnames = map { $_->name } @{ $_[0]{'packages'} };
              print <<'END_MSG';
:: the following package(s) cannot be upgraded due to
:: unresolvable dependencies:
END_MSG
              $self->display_list( q{ } x 5, @pkgnames );
              $self->promptny( 'Do you want to skip the above '
                               . 'package(s) for this upgrade?' );
          },
          'local_newer' => sub {
              return 1 if ( $self->{'opts'}{'downloadonly'} );

              my $pkg = shift->{'package'};
              $self->promptyn( sprintf ':: %s-%s: local version is newer. '
                               . 'Upgrade anyways?',
                               $pkg->name,
                               $pkg->version );
          },
          'corrupted_file' => sub {
              my $filename = $_[0]{'filename'};
              $self->promptyn( ":: File $filename is corrupted. "
                               . 'Do you want to delete it?' );
          },
         );
    
}

# We run a transaction, calling the given method on the transaction object
# for each argument we are passed on the command-line...
sub _run_protected
{
    my ($self, $pkgs_ref, $opts_ref) = @_;

    $self->_check_root;

    $self->fatal( 'no targets specified (use -h for help)' )
        unless @$pkgs_ref;

    my $method_name = $self->{'trans_method'}
        or die qq{INTERNAL ERROR: 'trans_method' is unset};
    my $trans = $self->transaction();
    my $method = $ALPM::Transaction::{ $method_name }
        or die qq{INTERNAL ERROR: invalid method name: $method_name};

    for my $pkgname ( @$pkgs_ref ) {
        eval { $method->( $trans, $pkgname ) } and next;

        # Match the error message to pacman's...
        $@ =~ s/\AALPM Error: //;
        $@ =~ s/ at .*\n\z//;
        $self->fatal( qq{'$pkgname': $@} );
    }

    eval {
        $trans->prepare;
        if ( $opts_ref->{'print'} ) {
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
sub prompt_yesno
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

sub prompt_yn
{
    my ($self) = shift;
    return $self->prompt_yesno( shift, 'y' );
}

sub prompt_ny
{
    my ($self) = shift;
    return $self->prompt_yesno( shift, 'n' );
}

sub _display_packages
{
    my ($self, $prefix, @pkgs) = @_;

    my $makedesc = ( $self->{'cfg'}{'showsize'}
                     ? sub {
                         sprintf '%s-%s [%.2f MB]',
                             ( $_->name, $_->version,
                               $_->size / ( 1024 * 1024 ) );
                     }
                     : sub {
                         sprintf '%s-%s', ( $_->name, $_->version );
                     } );

    return $self->display_list( $prefix,
                                map { $makedesc->( $_ ) } @pkgs );
}

sub display_list
{
    my ($self, $prefix, @strings) = @_;

    $prefix .= q{ };
    my $LINE_MAX = 78 - length $prefix;

    my $descs    = [];
    my @lines    = $descs;
    my $desclens = 0;

    # We take a list of descriptions and word-wrap them.  The
    # reason we don't use Text::Wrap is because descriptions may have
    # spaces inside them.  We don't want to split on these spaces.

    DESC_LOOP:
    for my $desc ( @strings) {
        # Count the length of spaces inbetween that we'll insert later...
        my $spaceslen = @$descs > 1 ? ( @$descs-1 ) * 2 : 0;
        my $newlen    = ( length $desc ) + $desclens;

        # If we have room to add another description to the line...
        if ( $newlen + $spaceslen <= $LINE_MAX ) {
            $desclens = $newlen;
            push @$descs, $desc;
            next DESC_LOOP;
        }
        
        # Otherwise we ran out of room, create a new line...
        push @lines, ( $descs = [ $desc ] );
        $desclens = length $desc;
    }

    # Convert arrayrefs of descriptions into strings w/ spaces inbetween...
    @lines = map { join q{  }, @{$_} } @lines;

    my $indent = q{ } x ( length $prefix );
    print "\n", map { $_, "\n" } ( $prefix . ( shift @lines ),
                                   map { $indent . $_ } @lines ), q{};

    return;
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

    printf "Total Removed Size:   %.2f MB\n\n", $isize / ( 1024 * 1024 );

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

    printf "Total Download Size:    %.2f MB\n",
        $dlsize / ( 1024 * 1024 );

    unless ( $self->{'opts'}{'dlonly'} ) {
        printf "Total Installed Size:   %.2f MB\n",
            $dlsize / ( 1024 * 1024 );
    }

    print "\n";
}

sub display_optdepends
{
    my ($self, $pkg) = @_;

    my $optdepends = $pkg->optdepends;
    return unless @$optdepends;

    printf "Optional dependencies for %s\n", $pkg->name;
    $self->display_list( q{ } x 3, @$optdepends );

    return;
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
