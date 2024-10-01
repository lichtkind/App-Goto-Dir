#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 5;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use App::Goto::Dir::Data;
my $class = 'App::Goto::Dir::Data';

use_ok( $class );
my $d = App::Goto::Dir::Data->new();
is( ref $d,  $class, 'created empty data store');
my $c = $d->get_config;
is( ref $c,  'HASH', 'empty data store has default configuration');
my $state = $d->state;
is( ref $state,  'HASH', 'serialized empty data store');
is( ref App::Goto::Dir::Data->restate( $state ),  $class, 'recreated empty data store');


my ($drive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );

my $def_entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
my $h_entry = App::Goto::Dir::Data::Entry->new( $dir, 'here' );


exit 0;
