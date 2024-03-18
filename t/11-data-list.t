#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 33;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::List';
use_ok( $class );

my $def_entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
my ($dive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );
my $h_entry = App::Goto::Dir::Data::Entry->new( $dir, 'here' );
