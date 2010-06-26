package ALPM::LoadConfig;

use warnings;
use strict;

use List::Util qw();
use IO::Handle qw();
use English    qw(-no_match_vars);
use Carp       qw();
use ALPM       qw();

##------------------------------------------------------------------------
## GLOBALS
##------------------------------------------------------------------------

my %_CFG_OPTS =
    qw{ RootDir   root       CacheDir     cachedirs    DBPath       dbpath
        LogFile   logfile    UseSyslog    usesyslog    UseDelta     usedelta
        IgnorePkg ignorepkgs IgnoreGroup  ignoregrps   NoUpgrade    noupgrades
        NoExtract noextracts NoPassiveFtp nopassiveftp Architecture arch};

# The following options are implemented in pacman and not ALPM so are ignored:
my @NULL_OPTS = qw{ HoldPkg SyncFirst CleanMethod XferCommand
                    ShowSize TotalDownload };

my $COMMENT_MATCH = qr/ \A \s* [#] /xms;
my $SECTION_MATCH = qr/ \A \s* [[] (\w+) []] \s* \z /xms;
my $FIELD_MATCH   = qr/ \A \s* (\w+) \s* = \s* ([^\n]*) /xms;

##------------------------------------------------------------------------
## PRIVATE FUNCTIONS
##------------------------------------------------------------------------

sub _null_sub
{
    1;
}

sub _make_parser
{
    my ($path, $hooks) = @_;

    open my $cfg_file, '<', $path
        or die "Could not open config file $path: $OS_ERROR\n";

    my $parse_line_ref =
        sub {
            my $line = shift;

            # Trim any extra whitespace...
            $line =~ s/\A\s+//;
            $line =~ s/\s+\z//;

            # Ignore empty lines & comments...
            return unless ( length $line );
            return if ( $line =~ /$COMMENT_MATCH/xms );

            eval {
                # Call the appropriate hook for each type of token...
                if ( my ($section_name) = $line =~ /$SECTION_MATCH/) {
                    $hooks->{section}->($section_name);
                    return;
                }
                elsif ( my ($field_name, $field_val) =
                        $line =~ /$FIELD_MATCH/ ) {
                    return unless $field_val;

                    # Not sure if I should warn or not...
                    # warn qq{Unrecognized field named "$field_name"\n}
                    my $field_store = $hooks->{field}{$field_name}
                        or return;

                    $field_store->( $field_val );
                    return;
                }
                die "Invalid line in config file, not a comment, section, " .
                    "or field\n";
            };

            # Print the offending file and line number along with any errors...
            # (This is why we use dies with newlines, for cascading error msgs)
            die "$EVAL_ERROR$path:${\$cfg_file->input_line_number()} $line\n"
                if ( $EVAL_ERROR );
        };

    return
        sub {
            while ( my $cfg_line = <$cfg_file> ) {
                chomp $cfg_line;
                $parse_line_ref->($cfg_line);
            }
            close $cfg_file;
        };
}

sub _register_db
{
    my ($url, $section) = @_;
    die qq{Section has not previously been declared, cannot set URL\n}
        unless ( $section );
    ALPM->register_db( $section => $url );
    return;
}

sub _set_defaults
{
    ALPM->set_options({ root        => '/',
                        dbpath      => '/var/lib/pacman/',
                        cachedirs   => [ '/var/cache/pacman/pkg' ],
                        logfile     => '/var/log/pacman.log', });
}

##------------------------------------------------------------------------
## PUBLIC METHODS
##------------------------------------------------------------------------

sub new
{
    my $class = shift;

    Carp::croak( "Invalid arguments to ALPM::LoadConfig::new.\n" .
                 'Arguments must be a hash' )
        unless @_ % 2 == 0;

    my %params = @_;
    my $custom_fields_ref = $params{ custom_fields };

    Carp::croak( "Invalid arguments to ALPM::LoadConfig::new.\n" .
                 'Hash argument must have coderefs as values' )
        if List::Util::first { ref $_ ne 'CODE' }
            values %{ $custom_fields_ref };

    bless { custom_fields => $custom_fields_ref,
            auto_register => $params{ 'auto_register' } || 1,
           }, $class;
}

sub load_file
{
    my ($self, $cfg_path) = @_;

    my $current_section; # used for state in our closures

    # Setup hooks for 'Include'ed file parsers...
    my $include_hooks =
    { section => sub {
          my $file = shift;
          die  q{Section declaration is not allowed in } .
              qq{Include-ed file\n($file)\n};
      },
      field   => { Server => sub {
                       my $server_url = shift;
                       _register_db( $server_url, $current_section )
                   } },
     };

    my $field_hooks =
    {
     ( map {
         my $field_name = $_;
         my $opt_name   = $_CFG_OPTS{$_};
         # create hash of field names to hooks
         $_ => ( $opt_name =~ /s\z/ ? 

                 # plural options get set arrayref values
                 sub { 
                     my $cfg_value = shift;
                     die qq{$field_name can only be set in the} .
                         qq{[options] section\n}
                             unless ( $current_section eq 'options' );
                     ALPM->set_opt( $opt_name, [ split /\s+/, $cfg_value ] );
                 }

                 :

                 # singular options get scalar values
                 sub {
                     my $cfg_value = shift;
                     die qq{$field_name can only be set in the } .
                         qq{[options] section\n}
                             unless ( $current_section eq 'options' );
                     ALPM->set_opt( $opt_name, $cfg_value );
                 }
                )
     } keys %_CFG_OPTS ),

     # these fields do nothing, for now...
     ( map { ( $_ => \&_null_sub ) } @NULL_OPTS ),

     Server  => sub { _register_db( shift, $current_section ) },
     Include => sub {
         die "Cannot have an Include directive in the [options] section\n"
             if ( $current_section eq 'options' );

         # An include directive spawns its own little parser...
         my $inc_path   = shift;
         my $parser_ref = _make_parser( $inc_path, $include_hooks );
         $parser_ref->();
     },

     # aaaand SHAZAM! customize!
     %{ $self->{'custom_fields'} },
    }; # end of field_hooks hashref brackets

    # Now we have hooks for parsing the main config file...
    my $parser_hooks = { field   => $field_hooks,
                         section => sub { $current_section = shift;}
                        };

    # Load default values like pacman does...
    _set_defaults();

    _make_parser( $cfg_path, $parser_hooks )->();

    if ( $self->{'auto_register'} ) {
        ALPM->register( 'local' );
    }

    return;
}

1;

__END__

=head1 NAME

ALPM::LoadConfig - pacman.conf config file parsing class.

=head1 SYNOPSIS

  # At startup:
  use ALPM qw( /etc/pacman.conf );

  # At runtime:
  ALPM->load_config('/etc/pacman.conf');

  # Load custom fields as well:
  my $value;
  my %fields = ( 'CustomField' => sub { $value = shift } );
  my $loader = ALPM::LoadConfig->new( custom_fields => \%fields,
                                      auto_register => 0 );
  $loader->load_file( '/etc/pacman.conf' );

=head1 DESCRIPTION

This class is used internally by ALPM to parse pacman.conf config
files.  The settings are used to set ALPM options.  You probably don't
need to use this module directly.

=head1 CONSTRUCTOR

=head2 new

 $OBJ = ALPM::LoadConfig->new( [ custom_fields => \%FIELDS_REF,  ]
                               [ auto_register => $AUTO_REGISTER ] );

=over 4

=item B<Parameters>

=over 4

=item C<\%FIELDS_REF> (Hash Reference) (Optional)

Keys are field names from the C</etc/pacman.conf> configuration file.
Values are code references.  When a field is found inside the
configuration file with the I<exact same> name, then the code
reference is called, passed the value of the entry as the only
argument.

=item C<$AUTO_REGISTER> (Optional)

Normally, LoadConfig will automatically call
C<< ALPM->register_db( 'local' ) >>
to register the local database after it has read the config file.  If
you want to override certain ALPM settings immediately after reading
the config file you will have to turn this feature off.  This is used
as a boolean value, set it to 0 to disable automatic localdb
registering.

=back

=back

=head1 METHODS

=head2 load_config

 undef = $OBJ->load_config( $CFG_FILE_PATH )

This method will read a configuration file, setting ALPM options as it
goes.

=over 4

=item B<Parameters>

=over 4

=item C<$CFG_FILE_PATH>

The path to the configuration file to read.

=back

=back

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
