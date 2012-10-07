package ALPM;
use warnings;
use strict;

our $VERSION;
BEGIN {
	$VERSION = '2.01';
	require Carp;
	require ALPM::Transaction;
	require ALPM::Package;
	require ALPM::DB;
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
}

# Transaction Constants #
my %_TRANS_FLAGS = (
	'nodeps' => (1 << 0),
	'force' => (1 << 1),
	'nosave' => (1 << 2),
	'nodepver' => (1 << 3),
	'cascade' => (1 << 4),
	'recurse' => (1 << 5),
	'dbonly' => (1 << 6),
	'alldeps' => (1 << 8),
	'dlonly' => (1 << 9),
	'noscriptlet' => (1 << 10),
	'noconflicts' => (1 << 11),
	'needed' => (1 << 13),
	'allexplicit' => (1 << 14),
	'unneeded' => (1 << 15),
	'recurseall' => (1 << 16),
	'nolock' => (1 << 17),
);

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

sub trans
{
	my $self = shift;
	Carp::croak 'arguments to trans method must be a hash' unless(@_ % 2 == 0);

	my %opts  = @_;
	my $flags = 0;

	# Parse flags if they are provided...
	if(exists $opts{'flags'}){
		for my $flag (split /\s+/, $opts{'flags'}) {
			my $f = $_TRANS_FLAGS{$flag}
				or Carp::croak qq{unknown transaction flag "$flag"};
			$flags |= $f;
		}
	}

	eval {
		_trans_init($self, $flags, @opts{'event', 'conv', 'progress'});
	};
	if($@){
		die unless($@ =~ /\AALPM Error:/);
		$@ =~ s/ at .*? line \d+[.]\n//;
		Carp::croak $@;
	}

	# Create an object that will automatically release the transaction
	# when destroyed...
	return ALPM::Transaction->new(%opts);
}

1;
