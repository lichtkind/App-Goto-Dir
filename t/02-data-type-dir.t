#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 10;
use File::Spec;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::Directory';
my ($dive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = File::Spec->rel2abs( $dir );

use_ok( $class );
my $obj = App::Goto::Dir::Data::ValueType::Directory->new( $ENV{'HOME'} );
is( ref $obj, $class, 'Created first object');
is( $obj->get, '~', 'dir was just the home dir, which got folded');
is( $obj->format(0), '~', 'display with folded home dir');
is( $obj->format(1), $ENV{'HOME'}, 'display with not folded home dir');
is( $obj->format(0), '~', 'display default is foleded');
$obj->set('/path/to/nowhere');
is( $obj->get, '~', 'bad dir was not accepted');
is( ref App::Goto::Dir::Data::ValueType::Directory->new(), '', 'need a value to create object');
is( ref App::Goto::Dir::Data::ValueType::Directory->new('/path/to/nowhere'), '', 'need an existing dir');

$obj->set( $dir );
is( $obj->format(1), $adir, 'folded dir back correctly and expanded t absolute');

exit 0;
