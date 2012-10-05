package ALPM::LoadConfig;

use warnings;
use strict;

use IO::Handle qw();
use List::Util qw();
use English qw(-no_match_vars);
use ALPM qw();
use Carp qw();

##------------------------------------------------------------------------
## GLOBALS
##------------------------------------------------------------------------

my %CFG_OPTS = (
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

sub _make_parser
{
	my($path, $hooks) = @_;

	my $parser = sub {
		local $_ = shift;

		# Trim any extra whitespace...
		s/\A\s+//; s/\s+\z//;

		return unless(length);
		eval {
			# Call the appropriate hook for each type of token...
			if(/$COMMENT_MATCH/){
				;
			}elseif(/$SECTION_MATCH/){
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

		if($@){
			# Print the offending file and line number along with any errors...
			# (This is why we use dies with newlines, for cascading error msgs)
			my $lineno = $if->input_line_number();
			die "$EVAL_ERROR$path:$lineno $line\n"
		}
	};

	open my $if, '<', $path or die "open $path: $!\n";
	return sub {
		while(my $ln = <$if>){
			chomp $ln;
			$parser->($ln);
		}
		close $if;
	};
}

sub _register
{
	my($url, $section) = @_;
	die qq{Section has not previously been declared, cannot set URL\n}
		unless($section);
	ALPM->register($section => $url);
	return;
}

sub _set_defaults
{
	ALPM->set_options({
		'root' => '/',
		'dbpath' => '/var/lib/pacman/',
		'cachedirs' => [ '/var/cache/pacman/pkg' ],
		'logfile' => '/var/log/pacman.log',
	});
}

##------------------------------------------------------------------------
## PUBLIC METHODS
##------------------------------------------------------------------------

sub new
{
	my $class = shift;
	unless(@_ % 2 == 0){
		Carp::croak('Arguments to ALPM::LoadConfig->new must be a hash');
	}

	my %params = @_;
	my $cfields = $params{'cfields'};

	if(grep { ref $_ ne 'CODE' } values %$cfields){
		Carp::croak('Hash arg to ALPM::LoadConfig->new must have coderefs as values' )
	}

	bless { 'cfields' => $cfields }, $class;
}

sub load_file
{
	my($self, $cfg_path) = @_;

	my $current_section; # used for state in our closures

	# Setup hooks for 'Include'ed file parsers...
	my $include_hooks =
	{ section => sub {
		  my $file = shift;
		  die  q{Section declaration is not allowed in } .
			  qq{Include-ed file\n($file)\n};
	  },
	  field   => { Server => sub {
					   my $server_url = shift;
					   _register( $server_url, $current_section )
				   } },
	 };

	my $field_hooks =
	{
	 ( map {
		 my $field_name = $_;
		 my $opt_name   = $CFG_OPTS{$_};
		 # create hash of field names to hooks
		 $_ => ( $opt_name =~ /s\z/ ? 

				 # plural options get set arrayref values
				 sub { 
					 my $cfg_value = shift;
					 die qq{$field_name can only be set in the} .
						 qq{[options] section\n}
							 unless ( $current_section eq 'options' );
					 ALPM->set_opt( $opt_name, [ split /\s+/, $cfg_value ] );
				 }

				 :

				 # singular options get scalar values
				 sub {
					 my $cfg_value = shift;
					 die qq{$field_name can only be set in the } .
						 qq{[options] section\n}
							 unless ( $current_section eq 'options' );
					 ALPM->set_opt( $opt_name, $cfg_value );
				 }
				)
	 } keys %CFG_OPTS ),

	 # these fields do nothing
	 ( map { ( $_ => \&_null ) } @NULL_OPTS ),

	 Server  => sub { _register( shift, $current_section ) },
	 Include => sub {
		 die "Cannot have an Include directive in the [options] section\n"
			 if ( $current_section eq 'options' );

		 # An include directive spawns its own little parser...
		 my $inc_path   = shift;
		 my $parser_ref = _make_parser( $inc_path, $include_hooks );
		 $parser_ref->();
	 },

	 # aaaand SHAZAM! customize!
	 %{ $self->{'cfields'} },
	}; # end of field_hooks hashref brackets

	# Now we have hooks for parsing the main config file...
	my $parser_hooks = { field   => $field_hooks,
						 section => sub { $current_section = shift;}
						};

	# Load default values like pacman does...
	_set_defaults();

	_make_parser( $cfg_path, $parser_hooks )->();

	return;
}

1;

__END__

=head1 NAME

ALPM::LoadConfig - pacman.conf config file parsing class.

=head1 SYNOPSIS

  # At startup:
  use ALPM qw( /etc/pacman.conf );

  # At runtime:
  ALPM->load_config('/etc/pacman.conf');

  # Load custom fields as well:
  my $value;
  my %fields = ( 'CustomField' => sub { $value = shift } );
  my $loader = ALPM::LoadConfig->new('cfields' => \%fields );
  $loader->load_file( '/etc/pacman.conf' );

=head1 DESCRIPTION

This class is used internally by ALPM to parse pacman.conf config
files.  The settings are used to set ALPM options.  You probably don't
need to use this module directly.

=head1 CONSTRUCTOR

=head2 new

 $OBJ = ALPM::LoadConfig->new('cfields' => \%FIELDS_REF? );

=over 4

=item B<Parameters>

=over 4

=item C<\%FIELDS_REF> B<(Hash Reference) (Optional)>

Keys are field names from the C</etc/pacman.conf> configuration file.
Values are code references.  When a field is found inside the
configuration file with the I<exact same> name, then the code
reference is called, passed the value of the entry as the only
argument.

=back

=head1 METHODS

=head2 load_config

 undef = $OBJ->load_config( $CFG_FILE_PATH )

This method will read a configuration file, setting ALPM options as it
goes.

=over 4

=item B<Parameters>

=over 4

=item C<$CFG_FILE_PATH>

The path to the configuration file to read.

=back

=back

=head1 SEE ALSO

L<ALPM>

=head1 AUTHOR

Justin Davis, C<< <juster at cpan dot org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Justin Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
