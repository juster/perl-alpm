#!/usr/bin/perl
use Test::More tests => 4;
use warnings;
use strict;
use Devel::Peek;

BEGIN {
    use_ok('ALPM');
};

ok( ALPM->load_config('t/pacman.conf') );
ok( my $local = ALPM->register_db );
ok( my $dbs = ALPM->get_opt('syncdbs') );

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
