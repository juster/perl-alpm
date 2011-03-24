#!/usr/bin/perl
use Test::More;
use warnings;
use strict;

#use Devel::Peek;

if ( -e '/etc/pacman.conf' ) {
    plan tests => 4;
}
else {
    plan skip_all => 'This test requires /etc/pacmanf.conf';
}

ok( require ALPM );
ok( ALPM->load_config('/etc/pacman.conf') );
ok( my $local = ALPM->localdb );
ok( my $dbs   = ALPM->syncdbs );

# use Data::Dumper;
# print STDERR Dumper($dbs);

# for my $db ( @$dbs ) {
#     print STDERR $db->get_name, " -- ", $db->get_url, "\n";
# }

# my @perl_pkgs;
# for my $repo ( qw/ community extra core / ) {
#     ok( my $repo_db = ALPM->get_repo_db($repo) );

#     push @perl_pkgs, @{$repo_db->search(['perl'])};
# }

# @perl_pkgs = grep { $_->get_name =~ /perl/ && $_->get_name !~ /\Aperl-/ }
#     sort { $a->get_name cmp $b->get_name } @perl_pkgs;

# for my $pkg (@perl_pkgs) {
#     print STDERR $pkg->get_name, "\n";
# }
# printf STDERR "%d perl packages with non-standard names.\n", scalar @perl_pkgs;
