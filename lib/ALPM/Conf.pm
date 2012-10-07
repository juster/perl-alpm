package ALPM::Conf;
use warnings;
use strict;

BEGIN {
	require IO::Handle;
	require Carp;
	require ALPM;
}

## Private functions.

# These options are implemented in pacman, not libalpm, and are ignored.
my @NULL_OPTS = qw{HoldPkg SyncFirst CleanMethod XferCommand
	TotalDownload VerbosePkgLists};

sub _null
{
	1;
}

my $COMMENT_MATCH = qr/ \A \s* [#] /xms;
my $SECTION_MATCH = qr/ \A \s* \[ ([^\]]+) \] \s* \z /xms;
my $FIELD_MATCH = qr/ \A \s* ([^=\s]+) (?: \s* = \s* ([^\n]*))? /xms;
sub _mkparser
{
	my($path, $hooks) = @_;
	sub {
		local $_ = shift;
		s/^\s+//; s/\s+$//; # trim whitespace
		return unless(length);

		# Call the appropriate hook for each type of token...
		if(/$COMMENT_MATCH/){
			;
		}elsif(/$SECTION_MATCH/){
			$hooks->{'section'}->($1);
		}elsif(/$FIELD_MATCH/){
			my($name, $val) = ($1, $2);
			if(length $val){
				my $apply = $hooks->{'field'}{$name};
				$apply->($val) if($apply);
			}
		}else{
			die "Invalid line in config file, not a comment, section, or field\n";
		}
	};
}

sub _parse
{
	my($path, $hooks) = @_;

	my $parser = _mkparser($path, $hooks);
	my $line;
	open my $if, '<', $path or die "open $path: $!\n";
	eval {
		while(<$if>){
			chomp;
			$line = $_;
			$parser->($_);
		}
	};
	my $err = $@;
	close $if;
	if($err){
		# Print the offending file and line number along with any errors...
		# (This is why we use dies with newlines, for cascading error msgs)
		my $lineno = $if->input_line_number();
		die "$@$path:$lineno $line\n"
	}
	return;
}

sub _set_defaults
{
	my($alpm) = @_;
	unless($alpm->get_cachedirs){
		$alpm->set_cachedirs('/var/cache/pacman/pkg');
	}
	unless(eval { $alpm->get_logfile }){
		$alpm->set_logfile('/var/log/pacman.log');

	}
}

## Public methods.

sub new
{
	my($class, $path) = @_;
	bless { 'path' => $path }, $class;
}

sub custom_fields
{
	my($self, %cfields) = @_;
	if(grep { ref $_ ne 'CODE' } values %cfields){
		Carp::croak('Hash argument must have coderefs as values' )
	}
	$self->{'cfields'} = \%cfields;
}

sub _mlisthooks
{
	my($dbsref, $sectref) = @_;

	# Setup hooks for 'Include'ed file parsers...
	return {
		'section' => sub {
			my $file = shift;
			die q{Section declaration is not allowed in Include-ed file\n($file)\n};
	  	},
		'field' => {
			'Server' => sub { _addmirror($dbsref, shift, $$sectref) }
		},
	 };
}

my %CFGOPTS = (
	'RootDir' => 'root',
	'DBPath' => 'dbpath',
	'CacheDir' => 'cachedirs',
	'GPGDir' => 'gpgdir',
	'LogFile' => 'logfile',
	'UseSyslog' => 'usesyslog',
	'UseDelta' => 'usedelta',
	'CheckSpace' => 'checkspace',
	'IgnorePkg' => 'ignorepkgs',
	'IgnoreGroup' => 'ignoregrps',
	'NoUpgrade' => 'noupgrades',
	'NoExtract' => 'noextracts',
	'NoPassiveFtp' => 'nopassiveftp',
	'Architecture' => 'arch',
);

sub _confhooks
{
	my($optsref, $sectref) = @_;
	my %hooks;
	while(my($fld, $opt) = each %CFGOPTS){
		$hooks{$fld} = sub { 
			my $val = shift;
			die qq{$fld can only be set in the [options] section\n}
				unless($$sectref eq 'options');
			$optsref->{$opt} = $val;
		};
	 }
	return %hooks;
}

sub _nullhooks
{
	map { ($_ => \&_null) } @_
}

my $ARCH;
sub _addmirror
{
	my($dbs, $sect, $url) = @_;
	die "Section has not previously been declared, cannot set URL\n" unless($sect);

	# Expand $arch like pacman would do.
	$url =~ s{\$arch(/|\$)}{$ARCH}g;

	# The order databases are added must be preserved as must the order of URLs.
	my $fnd;
	for my $db (@$dbs){
		if($db->{'name'} eq $sect){
			$fnd = $db;
			last;
		}
	}
	unless($fnd){
		$fnd = { 'name' => $sect };
		push @$dbs, $fnd;
	}
	push @{$fnd->{'mirrors'}}, $url;
	return;
}


sub _setopt
{
	my($alpm, $opt, $valstr) = @_;
	no strict 'refs';
	my $meth = *{"ALPM::set_$opt"}{'CODE'};
	die "The ALPM::set_$opt method is missing" unless($meth);

	my @val = ($opt =~ /s$/ ? map { split } $valstr : $valstr);
	$meth->($alpm, @val);
}


sub _applyopts
{
	my($opts, $dbs) = @_;
	my ($root, $dbpath) = delete @{$opts}{'root', 'dbpath'};
	unless($root && $dbpath){
		Carp::croak 'RootDir and DBPath must be defined in .conf file';
	}

	my $alpm = ALPM->new($root, $dbpath);
	while(my ($opt, $val) = each %$opts){
		_setopt($alpm, $opt, $val);
	}

	for my $db (@$dbs){
		my $name = $db->{'name'};
		my $mirs = $db->{'mirrors'};
		next unless(@$mirs);

		my $db = $alpm->register($name, 'default');
		for my $url (@$mirs){
			$db->add_server($url);
		}
	}
	return $alpm;
}

sub parse_options
{
	my($self) = @_;

	chomp ($ARCH = `uname -m`); # used by _addmirror

	my (%opts, @dbs, $currsect);
	my %fldhooks = (
		_confhooks(\%opts, \$currsect),
		_nullhooks(@NULL_OPTS),
		'Server'  => sub { _addmirror(\@dbs, shift, $currsect) },
		'Include' => sub {
			die "Cannot have an Include directive in the [options] section\n"
				if($currsect eq 'options');

			# An include directive spawns its own little parser...
			_parse(shift, _mlisthooks(\@dbs, \$currsect));
		},
		($self->{'cfields'} ? %{$self->{'cfields'}} : ()),
	);

	my %hooks = (
		'field' => \%fldhooks,
		'section' => sub { $currsect = shift }
	);

	_parse($self->{'path'}, \%hooks);
	return _applyopts(\%opts, \@dbs);
}

## Import magic used for quick scripting.
# e.g: perl -MALPM::Conf=/etc/pacman.conf -le 'print $alpm->root'

sub import
{
	my($pkg, $path) = @_;
	my($dest) = caller;
	return unless($path);

	my $conf = $pkg->new($path);
	my $alpm = $conf->parse_options;
	no strict 'refs';
	*{"${dest}::alpm"} = \$alpm;
	return;
}

1;
