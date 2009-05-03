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
