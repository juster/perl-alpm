package App::PerlPacman;

use warnings;
use strict;

use Locale::gettext   qw();
use Getopt::Long      qw(GetOptionsFromArray);
use Exporter          qw();
use Fcntl             qw(SEEK_END);

use ALPM              qw();
use ALPM::LoadConfig  qw();

Getopt::Long::Configure qw(bundling no_ignore_case pass_through);

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(_T);

Locale::gettext::textdomain( 'pacman' );

sub _T
{
    return sprintf Locale::gettext::gettext( shift ), @_ if @_ > 1;
    Locale::gettext::gettext( shift );
}

sub new
{
    my $class = shift;

    bless { 'converse_cb' => undef,
            'progress_cb' => undef,
            'opts'        => {},
            'extra_args'  => q{},
            'cfg'      => {} }, $class;
}

#---CLASS METHOD---
sub parse_options
{
    my $self = shift;
    my @args = @_;

    my %opts;
    GetOptionsFromArray( \@args, \%opts, $self->option_spec() );

    $self->{'opts'}       = \%opts;
    $self->{'extra_args'} = \@args;

    return \@args, \%opts;
}

#---CLASS METHOD---
# Subclasses override this method
sub option_spec
{
    qw{ help|h config=s logfile=s noconfirm
        noprogressbar noscriplet verbose|v debug
        root|r=s dbpath|b=s cachedir=s

        version|V query|Q remove|R sync|S upgrade|U };
}

sub _converse_callback
{

}

sub _progress_callback
{

}

sub _loghandle
{
    my ($self) = @_;

    my $fh = $self->{'logfh'};
    return $fh if $fh;

    my $logpath = ALPM->get_opt( 'logfile' )
        or die "INTERNAL ERROR: logfile option is not set";
    open $fh, '>>', $logpath
        or die "INTERNAL ERROR: failed to open logfile ($logpath): $!";
    seek $fh, 0, SEEK_END;

    my $stdout = select $fh;
    $| = 1;
    select $stdout;

    return $self->{'logfh'} = $fh;
}

sub logaction
{
    my ($self, $fmt, @args) = @_;
    
    my $logh = $self->_loghandle;
    printf $logh $fmt, @args;
    return;
}

#---PRIVATE METHOD---
# Stores all pacman-specific fields inside $Config package var.
# This is used as a callback for ALPM::LoadConfig.
#--------------------
sub _pacman_field_handlers
{
    my ($self) = @_;

    my $config = $self->{'config'};
    my $field_handlers;

    my $handler = sub {
        my $field = shift;
        return sub { $config->{ $field } = shift };
    };

    for my $key ( qw{ HoldPkg SyncFirst CleanMethod XferCommand
                      ShowSize TotalDownload } ) {
        $field_handlers->{ $key }  = $handler->( $key );
    }

    return $field_handlers;
}

sub _prepare_alpm
{
    my ($self, $opts_ref) = @_;

    my $loader = ALPM::LoadConfig->new
        ( custom_fields => $self->_pacman_field_handlers(),
          auto_register => 0,
         );
    $loader->load_file( $opts_ref->{'config'} || '/etc/pacman.conf' );

    tie my %alpm, 'ALPM';
    for my $opt ( qw/ logfile root dbpath / ) {
        $alpm{ $opt } = $opts_ref->{ $opt } if $opts_ref->{ $opt };
    }

    push @{ $alpm{'cachedir'} }, $opts_ref->{'cachedir'}
        if $opts_ref->{'cachedir'};

    return;
}

# Override _run_protected instead of this...
# A list of command line arguments, split by whitepsace, are arguments...
sub run
{
    my $self = shift;
    my ($args, $opts) = $self->parse_options( @_ );

    my $retval = eval { $self->_run_protected( $args, $opts ) };
    return $retval if defined $retval;
    
    if ( $@ ) {
        print STDERR $@;
        return 1;
    }

    return 0;
}

# Catch errors inside this sub...
# Sub-classes override this method.
sub _run_protected
{
    my ($self, $args, $opts) = @_;

    # Display error if no options were specified...
    $self->fatal( 'no operation specified (use -h for help)' )
        unless ( %$opts );

    $self->_prepare_alpm( $opts );

    my @actions = grep { $opts->{ $_ } } qw/ query remove sync upgrade /;

    $self->fatal( 'only one operation may be used at a time' )
        if @actions > 1;

    if ( @actions == 0 ) {
        if ( $opts->{ 'help' } ) {
            $self->print_help();
            return 0;
        }
        $self->fatal( 'no operation specified (use -h for help)' );
    }

    my $subclass = "App::PerlPacman::" . ucfirst $actions[0];

    eval "require $subclass; 1;"
        or die "Internal error: failed to load $subclass...\n$@";

    if ( $opts->{'help'} ) {
        $subclass->print_help();
        return 0;
    }

    my $cmdobj = $subclass->new();
    return $cmdobj->run( @{$args} );
}

sub error
{
    my $class = shift;
    print STDERR $class->_error_msg( @_ );
    return;
}

sub _error_msg
{
    my $class = shift;
    _T("error: "), _T( join q{}, @_, "\n" );
}

sub fatal
{
    my $class = shift;
    die $class->_error_msg( @_ );
}

sub fatal_notargets
{
    my $self = shift;
    $self->fatal( "no targets specified (use -h for help)\n" );
}

sub print_help
{
    my $class = shift;
    print $class->help();
}

sub _translate
{
    my ($self, $text) = @_;

    my %cache;
    $text =~ s{ \| ( [^|]+ ) \| }
              { $cache{ $1 } ||=
                    do {
                        my $in = $1;
                        ( $in =~ s/_\z//
                          ? do { my $out = _T( $in."\n" );
                                 chomp $out;
                                 $out; }
                          : _T( $in ) )
                    }
                }xmsge;
    return $text;
}

sub help
{
    my $self = shift;

    my $usage = $self->_translate( <<'END_HELP' );
|usage|:  ppacman <|operation|> [...]
|operations:
|    ppacman {-h --help}
    ppacman {-V --version}
    ppacman {-Q --query}   [|options|] [|package(s)|]
    ppacman {-R --remove}  [|options|] <|package(s)|>
    ppacman {-S --sync}    [|options|] [|package(s)|]
    ppacman {-U --upgrade} [|options|] <|file(s)|>
END_HELP

    $usage .= _T( qq{\nuse '\%s {-h --help}' with an operation for available }
                  . qq{options\n}, 'ppacman' );
    return $usage;
}

1;

__END__
