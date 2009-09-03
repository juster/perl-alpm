package ALPM::Package;

use warnings;
use strict;

use English qw(-no_match_vars);
use base qw(Exporter);
use Carp qw(croak);
use ALPM;

my %_PKG_ATTRIBS = map { /^has_(.*)$/ ? ( $1 => $_ ) : ( $_ => $_ ) }
    qw { filename name version desc url
         builddate installdate packager md5sum
         arch size isize reason licenses
         groups depends optdepends conflicts
         provides deltas replaces files backup
         has_scriptlet has_force download_size };


#---HELPER METHOD---
#  Usage   : my $name = $pkg->attr('name');
#  Purpose : This is used by attribs().
#  Params  : The name of the attribute.
#  Returns : The attribute value.
#-------------------
sub _attr
{
    croak "Invalid arguments to attrib method" if (@_ != 2);
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

sub attribs
{
    my $self = shift;

    return [ map { $self->_attr($_) } @_ ]
        if ( @_ > 0 );

    return map { ( $_ => $self->_attr($_) ) } keys %_PKG_ATTRIBS;
}

sub attribs_ref
{
    my $self = shift;

    return ( @_ == 0 ? { $self->attribs(@_) } : [ $self->attribs(@_) ] );
}

1;

=head1 NAME

ALPM::Package - Class representing an alpm package

=head1 SYNOPSIS

  use ALPM qw( /etc/pacman.conf );
  my $perlpkg = ALPM->local_db->get_pkg('perl');

  # TMTOWTDI!

  my $name = $perlpkg->name();
  print "$name rocks!\n";

  print $perlpkg->attr('name'), " rocks!\n";

  my %attrs = $perlpkg->attribs();
  print "$attrs{name} rocks!\n";

  my $attrs_ref = $perlpkg->attribs_ref();
  print "attrs_ref->{name} rocks!\n";

  # Dependencies are given as array of hashrefs:
  print "$name depends on:\n";
  for my $dep ( @{ $perlpkg->depends() } ) {
      print "\t$dep->{name} $dep->{mod} $dep->{ver}\n";
  }

  # Others lists are arrayrefs of scalars:
  print "$name owns files:\n";
  for my $file ( @{ $perlpkg->files() } ) {
      print "\t$file\n";
  }

=head1 DESCRIPTION

This class is a wrapper for all of the C<alpm_pkg_...> C library functions
of libalpm.  You retrieve the package from the database and you can then
access its attributes.  Attributes are like L<ALPM>'s options.  There are
many different ways to access them.  You cannot modify a package.

=head1 ATTRIBUTES

There are three basic ways to access an attribute.  You can use the
accessor method that is specific to an attribute, you can use the
C<attr> method, or you can use the C<attribs> method.

=head2 ATTRIBUTE ACCESSORS

The accessors are named exactly the same as the C<alpm_pkg_get...>
functions.  They are easy to use if you only want a few attributes.

I have removed the get_ prefix on the accessors.  This is because you
can't really I<set> anything so you should know it's a get anyways.

=over

=item * filename

=item * name

=item * version

=item * desc

=item * url

=item * builddate

=item * installdate

=item * packager

=item * md5sum

=item * arch

=item * size

=item * isize

=item * reason

=item * licenses

=item * groups

=item * depends

=item * optdepends

=item * conflicts

=item * provides

=item * deltas

=item * replaces

=item * files

=item * backup

=item * has_scriptlet

=item * has_force

=item * download_size

=back

Attributes with plural names return an arrayref of strings.

depends is different because it returns an arrayref of hashrefs
(an AoH).  The hash has the following key-value pairs:

  |------+----------------------------------------|
  | Key  | Value                                  |
  |------+----------------------------------------|
  | name | Package name of the dependency         |
  | ver  | The version to compare the real one to |
  | mod  | The modifier of the dependency         |
  |      | ('==', '>=', '<=', '<', or '>')        |
  |------+----------------------------------------|

=head2 PERLISH METHODS

There are also more perlish ways to get attributes.  C<attr> is useful
if you have the name of the attribute in a scalar.  C<attribs> is useful
if you want to get all attributes at once in a hash, or many attributes
at once into a list or variables.

=head2 attr



=head2 attribs

  Usage   : my %attribs = $pkg->attribs();
            my ($name, $desc) = $pkg->attribs('name', 'desc');
  Params  : If you specify attribute names, their values are returned as
            a list.  Otherwise, returns a hash of all attributes.
  Returns : Either a hash or a list.

=head2 attribs_ref

  This is the same as attribs, but it returns a hashref or
  arrayref instead.

=head1 SEE ALSO

L<ALPM>, L<ALPM::DB>

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

