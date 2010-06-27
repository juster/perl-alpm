package App::PerlPacman::Upgrade;
use App::PerlPacman::Modifier;

use warnings;
use strict;

our @ISA = qw( App::PerlPacman::Modifier );

sub new
{
    my $class = shift;
    $class->SUPER::new( 'pkgfile', @_ );
}

sub option_spec
{
    qw{ asdeps asexplicit nodeps|d force|f dbonly|k print print-format=s
        config=s logfile=s noconfirm noprogressbar noscriptlet };
}

sub help
{
    return <<'END_HELP';
usage:  pacman {-U --upgrade} [options] <file(s)>
options:
      --asdeps         install packages as non-explicitly installed
      --asexplicit     install packages as explicitly installed
  -d, --nodeps         skip dependency checks
  -f, --force          force install, overwrite conflicting files
  -k, --dbonly         add database entries, do not install or keep existing files
      --print          only print the targets instead of performing the operation
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
    
}

1;
