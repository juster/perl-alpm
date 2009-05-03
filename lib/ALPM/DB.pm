package ALPM::DB;

use ALPM;

sub get_url
{
    my $self = shift;

    return undef if ( $self->get_name eq 'local' );
    return $self->get_url;
}

1;

=head1 NAME

ALPM::DB - Class to represent a libalpm database

=head1 SYNOPSIS

  ... load ALPM with options first ...

  my $localdb = ALPM->register_db;
  my $name    = $localdb->get_name;
  my $perl    = $localdb->get_pkg('perl');

  my $url       = 'ftp://ftp.archlinux.org/community/os/i686';
  my $syncdb    = ALPM->register_db( 'community' => $url );
  my $found_ref = $syncdb->search('perl');

  for my $pkg (@$found_ref) {
      print "$pkg->name $pkg->version\n";
  }

  my $cache = $syncdb->get_pkg_cache;

=head1 METHODS

=head2 get_name

  Usage   : my $name = $db->get_name;
  Returns : The name of the repository database.
            Ex: core, extra, community, etc...

=head1 get_url

  Usage   : my $url = $db->get_url;
  Returns : The url of the repository, the same one the DB
            was initialized with or the empty string if this
            is a 'local' database.

=head2 get_pkg

  Usage   : my $package = $db->get_pkg($package_name)
  Params  : $package_name - Exact name of the package to retrieve.
  Returns : An ALPM::Package object if the package is found.
            undef if the package with that name is not found.

=head2 search

  Usage   : my $results_ref = $db->search([ 'foo', 'bar', ... ]);
  Params  : An arrayref of the strings to search for.
  Returns : An arrayref of package objects that matched the search.

=head2 get_pkg_cache

  Usage   : my $cache_ref = $db->get_pkg_cache;
  Returns : An arrayref of package objects in the DB cache.

=head1 SEE ALSO

L<ALPM>, L<ALPM::Package>

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

