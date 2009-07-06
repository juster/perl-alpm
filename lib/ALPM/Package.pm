package ALPM::Package;

use warnings;
use strict;

use English qw(-no_match_vars);
use base qw(Exporter);
use Carp qw(croak);
use ALPM;

my %_PKG_ATTRIBS = map { /^(?:get|has)_(.*)$/ ? ( $1 => $_ ) : ( $_ => $_ ) }
    qw { get_filename get_name get_version get_desc get_url
         get_builddate get_installdate get_packager get_md5sum
         get_arch get_size get_isize get_reason get_licenses
         get_groups get_depends get_optdepends get_conflicts
         get_provides get_deltas get_replaces get_files get_backup
         has_scriptlet has_force download_size };

sub get_attr
{
    croak "Invalid arguments to get_attrib method" if (@_ != 2);
    my ($self, $attrib_name) = @_;

    croak qq{Unknown package attribute "$attrib_name"}
        unless ( exists $_PKG_ATTRIBS{$attrib_name} );

    my $method_name = $_PKG_ATTRIBS{$attrib_name};

    my $method_ref = $ALPM::Package::{$method_name};
    my $result = eval { $method_ref->($self) };
    if ($EVAL_ERROR) {
        # For ALPM errors, show the line number of the calling script...
        croak $1 if ( $EVAL_ERROR =~ /^(ALPM .*) at .*? line \d+[.]$/ );
        croak $EVAL_ERROR;
    }

    return $result;
}

sub get_attribs_ref
{
    my $self = shift;

    return [ map { $self->get_attr($_) } @_ ]
        if ( @_ > 0 );

    my $attribs_ref;
    for my $attrib_name ( keys %_PKG_ATTRIBS ) {
        $attribs_ref->{$attrib_name} = $self->get_attr($attrib_name);
    }
    return $attribs_ref;
}

sub get_attribs
{
    my $self = shift;

    if ( @_ == 0 ) {
        return %{$self->get_attribs_ref(@_)};
    }

    return @{$self->get_attribs_ref(@_)};
}

1;

=head1 NAME

ALPM::Package - Class representing an alpm package

=head1 SYNOPSIS

  use ALPM qw( /etc/pacman.conf );
  my $perlpkg = ALPM->local_db->get_pkg('perl');

  # TMTOWTDI!

  my $name = $perlpkg->get_name();
  print "$name rocks!\n";

  print $perlpkg->get_attr('name'), " rocks!\n";

  my %attrs = $perlpkg->get_attribs();
  print "$attrs{name} rocks!\n";

  my $attrs_ref = $perlpkg->get_attribs_ref();
  print "attrs_ref->{name} rocks!\n";

  # Dependencies are given as array of hashrefs:
  print "$name depends on:\n";
  for my $dep ( @{ $perlpkg->get_depends() } ) {
      print "\t$dep->{name} $dep->{mod} $dep->{ver}\n";
  }

  # Others lists are arrayrefs of scalars:
  print "$name owns files:\n";
  for my $file ( @{ $perlpkg->get_files() } ) {
      print "\t$file\n";
  }

=head1 DESCRIPTION

This class is a wrapper for all of the C<alpm_pkg_...> C library functions
of libalpm.  You retrieve the package from the database and you can then
access its attributes.  Attributes are like L<ALPM>'s options.  There are
many different ways to access them.  Yet you cannot modify a package
using its methods.

=head1 ATTRIBUTES

There are three basic ways to access an attribute.  You can use the
accessor method that is specific to an attribute, you can use the
C<get_attr> method, or you can use the C<get_attribs> method.

=head2 ATTRIBUTE ACCESSORS

The accessors are named exactly the same as the C<alpm_pkg_get...>
functions.  They are easy to use if you only want a few attributes.

=over

=item get_filename

=item get_name

=item get_version

=item get_desc

=item get_url

=item get_builddate

=item get_installdate

=item get_packager

=item get_md5sum

=item get_arch

=item get_size

=item get_isize

=item get_reason

=item get_licenses

=item get_groups

=item get_depends

=item get_optdepends

=item get_conflicts

=item get_provides

=item get_deltas

=item get_replaces

=item get_files

=item get_backup

=item has_scriptlet

=item has_force

=item download_size

=back

=head2 PERLISH METHODS

There are also more perlish ways to get attributes.  C<get_attr> is useful
if you have the name of the attribute in a scalar.  C<get_attribs> is useful
if you want to get all attributes at once in a hash, or many attributes
at once into a list or variables.

=head2 get_attr

  Usage   : my $name = $pkg->get_attr('name');
  Params  : The name of the attribute.
            (use 'name' to call get_name, etc.
             use 'scriplet' to get has_scriptlet, etc.
             'download_size' is unchanged)
  Returns : The attribute value.

=head2 get_attribs

  Usage   : my %attribs = $pkg->get_attribs();
            my ($name, $desc) = $pkg->get_attribs('name', 'desc');
  Params  : If you specify attribute names, their values is returned as
            a list.  Otherwise, returns a hash of all attributes.
  Returns : Either a hash or a list.

=head2 get_attribs_ref

  This is the same as get_attribs, but it returns a hashref or
  arrayref instead.

=cut

