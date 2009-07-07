package ALPM::DB;

use ALPM;
use Carp qw(croak);

# Wrapper to automatically create a transaction...
sub update
{
    my $self = shift;

    croak "unable to update database while a transaction is in process"
        if ( $ALPM::_Transaction );

    my $t = ALPM->transaction( type => 'sync' );
    $self->_update(1);
    $t = undef;
}

# Wrapper to keep ALPM from crashing...
sub get_url
{
    my $self = shift;

    return undef if ( $self->get_name eq 'local' );
    return $self->_get_url;
}

# Wrapper so people don't have to use arrayrefs.
sub search
{
    my $self = shift;

    my $results = eval { $self->_search( [ @_ ] ) };
    if ( $@ ) {
        die "$@\n" unless ( $@ =~ /\AALPM Error:/ );
        $@ =~ s/ at .*? line \d+[.]\n//;
        croak $@;
    }

    return $results;
}

1;

=head1 NAME

ALPM::DB - Class to represent a libalpm database

=head1 SYNOPSIS

  ... load ALPM with options first ...

  my $localdb = ALPM->local_db;
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

=head2 get_url

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

  Usage   : my $results_ref = $db->search( 'foo', 'bar', ... );
  Params  : A list of strings to search for.
  Returns : An arrayref of package objects that matched the search.

=head2 get_pkg_cache

  Usage   : my $cache_ref = $db->get_pkg_cache;
  Returns : An arrayref of package objects in the DB cache.

=head2 update

  Usage   : $db->update;
  Purpose : Updates the local copy of the database's package list.
  Comment : This needs to create a transaction to work, so make sure
            you don't have any active transactions.

            Things may work incorrectly if the database is not updated.
            If there is no local db copy, the package cache will be empty.
  Returns : 1
  TODO    : Provide different return values like alpm does.

=head1 SEE ALSO

L<ALPM>, L<ALPM::Package>, L<ALPM::Transaction>

=head1 AUTHOR

Justin Davis, C<< <jrcd83 at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

