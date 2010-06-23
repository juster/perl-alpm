package App::PerlPacman::Remove;
use App::PerlPacman::Modifier;

use warnings;
use strict;

our @ISA = qw( App::PerlPacman::Modifier );

sub new
{
    my $class = shift;
    $class->SUPER::new( 'remove', @_ );
}

sub option_spec
{
    qw{ cascade|c nodeps|d dbonly|k nosave|n recursive|s+ uneeded|u
        print print-format=s noscriptlet };
}

sub help
{
    return <<'END_HELP';
    usage:  pacman {-R --remove} [options] <package(s)>
options:
  -c, --cascade        remove packages and all packages that depend on them
  -d, --nodeps         skip dependency checks
  -k, --dbonly         only remove database entries, do not remove files
  -n, --nosave         remove configuration files as well
  -s, --recursive      remove dependencies also (that won't break packages)
                       (-ss includes explicitly installed dependencies too)
  -u, --unneeded       remove unneeded packages (that won't break packages)
      --print          only print the targets instead of performing the
                       operation
      --print-format <string>
                       specify how the targets should be printed
      --config <path>  set an alternate configuration file
      --logfile <path> set an alternate log file
      --noconfirm      do not ask for any confirmation
      --noprogressbar  do not show a progress bar when downloading files
      --noscriptlet    do not execute the install scriptlet if one exists
  -v, --verbose        be verbose
      --debug          display debug messages
  -r, --root <path>    set an alternate installation root
  -b, --dbpath <path>  set an alternate database location
      --cachedir <dir> set an alternate package cache location
      --arch <arch>    set an alternate architecture
END_HELP
}

sub trans_confirm
{
    my ($self, $trans) = @_;

    $self->display_removals( $trans );
    return $self->prompt_yn( 'Do you want to remove these packages?' );
}

1;
