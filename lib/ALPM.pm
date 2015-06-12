package ALPM;
use warnings;
use strict;

use ALPM::Conflict;
use ALPM::Dependency;
use ALPM::Exception;
use ALPM::File;
use ALPM::FileConflict;
use ALPM::FileList;
use ALPM::MissingDependency;

our $VERSION;
BEGIN {
	$VERSION = '3.05';
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
}

## PUBLIC METHODS ##

sub dbs
{
	my($self) = @_;
	return ($self->localdb, $self->syncdbs);
}

sub db
{
	my($self, $name) = @_;
	for my $db ($self->dbs){
		return $db if($db->name eq $name);
	}
	return undef;
}

sub search
{
	my($self, @qry) = @_;
	return map { $_->search(@qry) } $self->dbs;
}

1;
