package App::PerlPacman;

use warnings;
use strict;

use Getopt::Long qw(GetOptionsFromArray);
use ALPM qw(/etc/pacman.conf);

Getopt::Long::Configure qw(bundling no_ignore_case pass_through);

sub parse_options
{
    my $class = shift;
    my @opts = @_;

    my %result;
    
    GetOptionsFromArray( \@opts, \%result, 'help|h',
                         $class->option_spec() );

    return \@opts, %result;
}

# Subclasses override this method
sub option_spec
{
    qw/ version|V query|Q remove|R sync|S upgrade|U /;
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

# Subclasses override this method...
sub run_opts
{
    my ($class, $extra_args, %opts) = @_;

    # Display error if no options were specified...
    $class->fatal( 'no operation specified (use -h for help)' )
        unless ( %opts );

    ACT_LOOP:
    for my $action ( qw/query remove sync upgrade/ ) {
        next ACT_LOOP unless $opts{ $action };
        my $subclass = "App::PerlPacman::" . ucfirst $action;

        eval "require $subclass; 1;"
            or die "Internal error: failed to load $subclass...\n$@";

        if ( $opts{'help'} ) {
            $subclass->print_help();
            return 0;
        }
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
