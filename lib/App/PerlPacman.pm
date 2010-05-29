package App::PerlPacman;

use warnings;
use strict;

use Getopt::Long qw(GetOptionsFromArray);
use ALPM;
use ALPM::LoadConfig;

Getopt::Long::Configure qw(bundling no_ignore_case pass_through);

our ($Converse_cb, $Progress_cb, %Config);

sub parse_options
{
    my $class = shift;
    my @opts = @_;

    my %result;
    GetOptionsFromArray( \@opts, \%result, $class->option_spec() );

    return \@opts, %result;
}

# Subclasses override this method
sub option_spec
{
    qw{ help|h config|c=s logfile|l=s noconfirm
        noprogressbar noscriplet verbose|v debug
        root|r dbpath|b cachedir

        version|V query|Q remove|R sync|S upgrade|U };
}

sub run
{
    my $class = shift;
    my ($extra_args, %opts) = $class->parse_options( @_ );

    my $retval = $class->run_opts( $extra_args, %opts );
    return $retval if defined $retval;

    $class->print_help() if $opts{'help'};
    die 'INTERNAL ERROR'; # shouldn't get here
}

sub _converse_callback
{

}

sub _progress_callback
{

}

#** HELPER FUNCTION
# Stores all pacman-specific fields inside $Config package var.
sub _pacman_field_handlers
{
    my $field_handlers;

    my $handler = sub {
        my $field = shift;
        return sub { $Config{ $field } = shift };
    };

    for my $key ( qw{ HoldPkg SyncFirst CleanMethod XferCommand
                      ShowSize TotalDownload } ) {
        $field_handlers->{ $key }  = $handler->( $key );
    }

    return $field_handlers;
}

sub prepare_alpm
{
    my ($class, %opts) = @_;

    my $loader = ALPM::LoadConfig->new
        ( custom_fields => _pacman_field_handlers(),
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
sub run_opts
{
    my ($class, $extra_args, %opts) = @_;

    # Display error if no options were specified...
    $class->fatal( 'no operation specified (use -h for help)' )
        unless ( %opts );

    $class->prepare_alpm( %opts );

    ACT_LOOP:
    for my $action ( qw/query remove sync upgrade/ ) {
        next ACT_LOOP unless $opts{ $action };
        my $subclass = "App::PerlPacman::" . ucfirst $action;

        eval "require $subclass; 1;"
            or die "Internal error: failed to load $subclass...\n$@";

        # if ( $opts{'help'} ) {
        #     $subclass->print_help();
        #     return 0;
        # }
        return $subclass->run( @{ $extra_args } );
    }

    return;
}

sub error
{
    my $class = shift;
    print STDERR "error: ", @_, "\n";
}

sub fatal
{
    my $class = shift;
    $class->error( @_ );
    exit 1;
}

sub fatal_notargets
{
    my $class = shift;
    $class->fatal( 'no targets specified (use -h for help)' );
}

sub print_help
{
    my $class = shift;
    print $class->help();
    exit 0;
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
