#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use App::Goto::Dir::Data;
my $class = 'App::Goto::Dir::Data';

use_ok( $class );

my ($drive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );

my $def_entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
my $h_entry = App::Goto::Dir::Data::Entry->new( $dir, 'here' );


exit 0;
