#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 18;
use File::Spec;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::Directory';
my ($drive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = File::Spec->rel2abs( $dir );

use_ok( $class );
my $obj = App::Goto::Dir::Data::ValueType::Directory->new( $ENV{'HOME'} );
is( ref $obj, $class, 'Created first object');
is( $obj->get, '~', 'dir was just the home dir, which got folded');
is( $obj->is_alive, 1,  'stored dir exists');
is( $obj->is_equal('~'), 1,  'dir equality recognized');
is( $obj->format(0), '~', 'display with folded home dir');
is( $obj->format(1), $ENV{'HOME'}, 'display with not folded home dir');
is( $obj->format(0), '~', 'display default is foleded');
$obj->set('/path/to/nowhere');
is( $obj->get, '~', 'bad dir was not accepted');
is( ref App::Goto::Dir::Data::ValueType::Directory->new(), '', 'need a value to create object');
is( ref App::Goto::Dir::Data::ValueType::Directory->new('/path/to/nowhere'), '', 'need an existing dir');

$obj->set( $dir );
is( $obj->format(1), $adir, 'folded dir back correctly and expanded t absolute');

my $state = $obj->state;
is( $obj->get,      $state, 'could retrieve inner state');
my $nobj = App::Goto::Dir::Data::ValueType::Directory->restate( $state );
is( ref $nobj,        $class, 'recreated object via restate');
is( $obj->get,     $obj->get, 'restated object has correct value');
is( $obj->is_alive,        1,  'current dir exists');
is( $obj->is_equal($adir), 1,  'equality with full dir recognized');
is( $obj->is_equal($dir),  1,  'equality with relative dir recognized');

exit 0;
