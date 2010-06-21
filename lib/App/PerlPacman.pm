package App::PerlPacman;

use warnings;
use strict;

use Getopt::Long qw(GetOptionsFromArray);
use ALPM;
use ALPM::LoadConfig;

Getopt::Long::Configure qw(bundling no_ignore_case pass_through);

sub new
{
    my $class = shift;
    my ($extra_args, %opts) = $class->parse_options( @_ );

    bless { 'converse_cb' => undef,
            'progress_cb' => undef,
            'opts'        => \%opts,
            'extra_args'  => $extra_args,
            'config'      => {} }, $class;
}

#---CLASS METHOD---
sub parse_options
{
    my $class = shift;
    my @opts = @_;

    my %result;
    GetOptionsFromArray( \@opts, \%result, $class->option_spec() );

    return \@opts, %result;
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

#---PRIVATE METHOD---
# Stores all pacman-specific fields inside $Config package var.
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

sub prepare_alpm
{
    my ($self, %opts) = @_;

    my $loader = ALPM::LoadConfig->new
        ( custom_fields => $self->_pacman_field_handlers(),
          auto_register => 0,
         );
    $loader->load_file( $opts{'config'} || '/etc/pacman.conf' );

    tie my %alpm, 'ALPM';
    for my $opt ( qw/ logfile root dbpath / ) {
        $alpm{ $opt } = $opts{ $opt } if $opts{ $opt };
    }

    push @{ $alpm{'cachedir'} }, $opts{'cachedir'}
        if $opts{'cachedir'};

    return;
}

# Subclasses override this method...
sub run
{
    my ($self) = @_;
    eval { $self->_run_protected() };
    if ( $@ ) {
        print STDERR $@;
        return 1;
    }
    return 0;
}

# Catch errors inside this sub...
sub _run_protected
{
    my ($self) = @_;

    my $extra_args = $self->{ 'extra_args' };
    my %opts       = %{ $self->{ 'opts' } };

    # Display error if no options were specified...
    $self->fatal( 'no operation specified (use -h for help)' )
        unless ( %opts );

    $self->prepare_alpm( %opts );

    my @actions = grep { $opts{ $_ } } qw/ query remove sync upgrade /;

    $self->fatal( 'only one operation may be used at a time' )
        if @actions > 1;

    if ( @actions == 0 ) {
        if ( $opts{ 'help' } ) {
            $self->print_help();
            return 0;
        }
        $self->fatal( 'no operation specified (use -h for help)' );
    }

    my $subclass = "App::PerlPacman::" . ucfirst $actions[0];

    eval "require $subclass; 1;"
        or die "Internal error: failed to load $subclass...\n$@";

    if ( $opts{'help'} ) {
        $subclass->print_help();
        return 0;
    }

    my $cmdobj = $subclass->new( @{ $extra_args } );
    return $cmdobj->run();
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
    join q{}, "error: ", @_, "\n";
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

sub help
{
    return <<'END_HELP';
usage:  ppacman <operation> [...]
operations:
    ppacman {-h --help}
    ppacman {-V --version}
    ppacman {-Q --query}   [options] [package(s)]
    ppacman {-R --remove}  [options] <package(s)>
    ppacman {-S --sync}    [options] [package(s)]
    ppacman {-U --upgrade} [options] <file(s)>

use 'ppacman {-h --help}' with an operation for available options
END_HELP
}

1;

__END__
