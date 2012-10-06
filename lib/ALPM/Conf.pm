package ALPM::Conf;

use warnings;
use strict;

use IO::Handle qw();
use English qw(-no_match_vars);
use Carp qw();

# The following options are implemented in pacman and not ALPM so they are ignored.
my @NULL_OPTS = qw{HoldPkg SyncFirst CleanMethod XferCommand
	TotalDownload VerbosePkgLists};

my $COMMENT_MATCH = qr/ \A \s* [#] /xms;
my $SECTION_MATCH = qr/ \A \s* \[ ([^\]]+) \] \s* \z /xms;
my $FIELD_MATCH = qr/ \A \s* ([^=\s]+) (?: \s* = \s* ([^\n]*))? /xms;

##------------------------------------------------------------------------
## PRIVATE FUNCTIONS
##------------------------------------------------------------------------

sub _null
{
	1;
}

sub _mkparser
{
	my($path, $hooks) = @_;
	sub {
		local $_ = shift;

		# Trim any extra whitespace...
		s/\A\s+//; s/\s+\z//;

		return unless(length);
		# Call the appropriate hook for each type of token...
		if(/$COMMENT_MATCH/){
			;
		}elsif(/$SECTION_MATCH/){
			$hooks->{'section'}->($1);
		}elsif(/$FIELD_MATCH/){
			my($name, $val) = ($1, $2);
			if($val){
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
		die "$EVAL_ERROR$path:$lineno $line\n"
	}

	return;
}

sub _register
{
	my($alpm, $url, $section) = @_;
	die "Section has not previously been declared, cannot set URL\n" unless($section);
	$alpm->register($section => $url);
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

##------------------------------------------------------------------------
## PUBLIC METHODS
##------------------------------------------------------------------------

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
	my($sect) = @_;

	# Setup hooks for 'Include'ed file parsers...
	return {
		'section' => sub {
			my $file = shift;
			die q{Section declaration is not allowed in Include-ed file\n($file)\n};
	  	},
		'field' => {
			'Server' => sub { _register(shift, $sect) }
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

sub _setopt
{
	my $alpm = shift;
	my $opt = shift;
	no strict 'refs';
	my $meth = *{"ALPM::set_$opt"}{'CODE'};
	die "set_$opt method is missing" unless($meth);
	$meth->($alpm, @_);
}

sub _confhooks
{
	my($alpm, $sectref) = @_;
	my %hooks;
	while(my($fld, $opt) = each %CFGOPTS){
		$hooks{$fld} = sub { 
			my $val = shift;
			die qq{$fld can only be set in the [options] section\n}
				unless($$sectref eq 'options');
			_setopt($alpm, $opt, map { split } $val);
		};
	 }
	return %hooks;
}

sub _nullhooks
{
	map { ($_ => \&_null) } @_
}

sub parse_options
{
	my($self, $alpm) = @_;

	my $currsect;
	my %cfields;
	%cfields = %{$self->{'cfields'}} if($self->{'cfields'});

	my %fldhooks = (
		_confhooks($alpm, \$currsect),
		_nullhooks(@NULL_OPTS),
		'Server'  => sub { _register( shift, $currsect ) },
		'Include' => sub {
			die "Cannot have an Include directive in the [options] section\n"
				if($currsect eq 'options');

			# An include directive spawns its own little parser...
			_parse(shift, _mlisthooks($currsect));
		},
		%cfields,
	);

	my %hooks = (
		'field' => \%fldhooks,
		'section' => sub { $currsect = shift }
	);

	# Load default values like pacman does...
	_set_defaults($alpm);
	_parse($self->{'path'}, \%hooks)->();

	return;
}

1;
