package App::PerlPacman;

use warnings;
use strict;

use Getopt::Long::Configure qw(bundling no_ignore_case);
use Getopt::Long qw(GetOptionsFromArray);

sub parse_options
{
    my @opts = @_;

    local @ARGV = @opts;
    my %result;
    
    GetOptionsFromArray( \@opts, \%options,
                         qw{ help
                             version|V query|Q remove|R sync|S upgrade|U },
                         '<>' => sub {
                                     push @{ $result{'packages'} }, @_
                                 },
                        );

    return %result;
}

sub run
{
    my $class = shift;
    my %opts  = $class->parse_options( @_ );

    use Dumpvalue;
    print Dumpvalue->new->dumpValue( \%opts );
}

1;

__END__
