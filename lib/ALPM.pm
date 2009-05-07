package ALPM;

use 5.010000;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);
use English qw(-no_match_vars);
use Carp;

use ALPM::Package;
use ALPM::DB;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('ALPM', $VERSION);

initialize();

END { release() };

# TODO: logcb dlcb totaldlcb
my %_IS_GETSETOPTION = ( map { ( $_ => 1 ) }
                         qw{ root dbpath cachedirs logfile usesyslog
                             noupgrades noextracts ignorepkgs holdpkgs ignoregrps
                             xfercommand nopassiveftp } );

my %_IS_GETOPTION    = ( %_IS_GETSETOPTION,
                         map { ( $_ => 1 ) } qw/ lockfile localdb syncdbs / );

####
#### CLASS FUNCTIONS
####

sub import
{
    croak 'Invalid arguments to import function' if ( @_ == 0 );
    return if ( @_ == 1 );

    my ($class) = shift;

    if ( @_ == 1) {
        my $opts_ref = shift;
        croak q{A single argument to ALPM's import must be a hash reference}
            unless ( ref $opts_ref eq 'HASH' );
        $class->set_options($opts_ref);
    }

    croak qq{Options to ALPM's import does not appear to be a hash}
        unless ( @_ % 2 == 0 );

    $class->set_options( { @_ } );

    return;
}

####
#### CLASS METHODS
####

sub get_opt
{
    croak 'Invalid arguments to get_opt' if ( @_ != 2 );
    my ($class, $optname) = @_;

    croak qq{Unknown libalpm option "$optname"} unless ( $_IS_GETOPTION{$optname} );

    my $method_name = "get_$optname";
    my $func_ref = $ALPM::{$method_name};

    my $result = eval { $func_ref->() };
    if ($EVAL_ERROR) {
        # For ALPM errors, show the line number of the calling script, not
        # the line number of this module...
        croak $1 if ( $EVAL_ERROR =~ /^(ALPM .*) at .*? line \d+[.]$/ );
        croak $EVAL_ERROR;
    }

    return $result;
}

sub set_opt
{
    croak 'Not enough arguments to set_opt' if ( @_ < 3 );
    my ($class, $optname, $optval) = @_;

    $optname = lc $optname;
    unless ( $_IS_GETSETOPTION{$optname} ) {
        carp qq{Given option "$optname" is not settable or unknown};
        return;
    }

    my $method_name = "set_$optname";
    my $func_ref = $ALPM::{$method_name};
    my $func_arg;

    # If the option is a plural, it can accept multiple arguments
    # and must take an arrayref as argument...
    $func_arg = ( $optname =~ /s$/            ?
                  # is multivalue opt
                  ( ref $optval eq 'ARRAY'      ?
                    $optval                     :
                    ( [ $optval, @_[ 3 .. $#_ ] ] ) # auto-convert args to aref
                   )                          :
                  # is single valued opt
                  ( ! ref $optval                 ?
                    $optval                       :
                    croak qq{Singular option "$optname" only takes a scalar value}
                   )
                 );

    return $func_ref->($func_arg);
}

sub get_options
{
    my $class = shift;

    if ( @_ == 0 ) {
        return %{$class->get_options_ref};
    }
    return @{$class->get_options_ref(@_)};
}

sub get_options_ref
{
    my $class = shift;

    # Return a list if option names are specified...
    return [ map { $class->get_opt($_) } @_ ]
        if ( @_ > 0 );

    # Return a hash of all options if no names are given...
    my $opts = {};
    for my $optname ( keys %_IS_GETOPTION ) {
        $opts->{$optname} = $class->get_opt($optname);
    }
    return $opts;
}

sub set_options
{
    croak 'Invalid arguments to set_options' if @_ != 2;
    my ($class, $opts_ref) = @_;

    for my $optname ( keys %{$opts_ref} ) {
        $class->set_opt( $optname, $opts_ref->{$optname} );
    }

    return 1;
}

sub register_db
{
    my $class = shift;

    if ( @_ == 0 ) {
        return db_register_local();
    }

    my $sync_name = shift;

    return db_register_local() if ( $sync_name eq 'local' );

    my $sync_url = shift;

    croak 'You must supply a URL for the database'
        unless ( defined $sync_url );

    # Replace the literal string '$repo' with the repo's name,
    # like in the pacman config file... bad idea maybe?
    $sync_url =~ s/\$repo/$sync_name/g;

    # Set the server right away because function calls break in between...
    my $new_db = db_register_sync($sync_name);
    $new_db->_set_server($sync_url);
    return $new_db;
}


1;

__END__

=head1 NAME

ALPM - Perl OO version of libalpm, Archlinux's packaging system

=head1 SYNOPSIS

  use ALPM;
  ALPM->set_options({ root        => '/',
                      dbpath      => '/var/lib/pacman/',
                      cachedirs   => [ '/var/cache/pacman/pkg' ],
                      logfile     => '/var/log/pacman.log',
                      xfercommand => '/usr/bin/wget --passive-ftp -c -O %o %u' });
  # ...is the same as...
  use ALPM ( root        => '/',
             dbpath      => '/var/lib/pacman/',
             cachedirs   => [ '/var/cache/pacman/pkg' ],
             logfile     => '/var/log/pacman.log',
             xfercommand => '/usr/bin/wget --passive-ftp -c -O %o %u' );

  # Lots of different ways to get/set ALPM options...
  my $root                  = ALPM->get_opt('root');
  my ($cachedirs, $localdb) = ALPM->get_options( 'cachedirs', 'localdb' );
  my $array_ref             = ALPM->get_options_ref( 'cachedirs', 'localdb' );
  my %allopts               = ALPM->get_options;
  my $allopts_ref           = ALPM_>get_options_ref; #hashref

  my $localdb = ALPM->register_db;
  my $pkg     = $localdb->get_pkg('perl');

  # Lots of different ways to get package attributes...
  my $attribs_ref    = $pkg->get_attribs_ref;
  my $name           = $pkg->get_name;
  my ($size, $isize) = $pkg->get_attribs('size', 'isize');
  print "$name $attribs_ref->{version} $attribs_ref->{arch} $size/$isize";

  my $syncdb = ALPM->register_db( 'extra',
                                  'ftp://ftp.archlinux.org/$repo/os/i686' );
  my $perlpkgs = $syncdb->search(['perl']);
  printf "%d perl packages found.\n", scalar @{$perlpkgs};

=head1 DESCRIPTION

Archlinux uses a package manager called pacman.  Pacman internally
uses the alpm library for handling its database of packages.  This
module is an attempt at creating a perlish object-oriented interface
to the libalpm C library.

=head2 EXPORT

None.

Because all alpm functions have been converted to class methods,
classes, and object methods, nothing is exported.

=head1 OPTIONS

ALPM has a number of options corresponding to the
C<alpm_option_get_...> and C<alpm_option_set...> C functions in the
library.  Options which take multiple values (hint: they have a plural
name) expect an array reference as an argument.  Similarly the same
options return multiple values as an array reference.

TODO

=head1 CLASS METHODS

ALPM has all its package specific and database specific functions
inside the package and database classes as methods.  Everything else
is accessed through class methods to ALPM.

As far as I can tell you cannot run multiple instances of libalpm.
Class methods help remind you of this.  The class method notation also
helps to differentiate between globally affecting ALPM functions and
package or database-specific functions.

=head2 set_options

=head2 set_opt

=head2 get_options

=head2 get_opt

=head2 register_db

  Usage   : my $localdb = ALPM->register_db;
            my $syncdb  = ALPM->register_db( 'core',
                                             'ftp://ftp.archlinux.org/$repo/os/i686' );
  Params  : No parameters will return the local database.
            Two parameters will register a sync database:
            1) The name of the repository to connect to.
            2) The URL to the repository's online files.
               Like with pacman's mirrorlist config file, $repo will be replaced
               with the repository name (argument 1) ... use single quotes!
  Precond : You must set options before using register_db.
  Throws  : An 'ALPM DB Error: ...' message is croaked on errors.
  Returns : An ALPM::DB object.

=head2 load_pkgfile

=head1 SEE ALSO

=over

=item * L<ALPM::Package>, L<ALPM::DB>

=item * L<http://code.toofishes.net/cgit/> - GIT repository for pacman/libalpm

=item * L<http://code.toofishes.net/pacman/doc/> - libalpm doxygen docs

=item * L<libalpm>(8) (pretty sparse)

=item * L<pacman>(8)

=back

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
