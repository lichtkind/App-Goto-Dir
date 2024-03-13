#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 20;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::Position';

use_ok( $class );

my $obj = App::Goto::Dir::Data::ValueType::Position->new();
is( ref $obj, $class, 'Created first object');




exit 0;

__END__

my $state = $obj->state;
is( $obj->get,      $state, 'could retrieve inner state');
my $nobj = App::Goto::Dir::Data::ValueType::Directory->restate( $state );
is( ref $nobj, $class, 'recreated object via restate');
is( $obj->get,   $obj->get, 'restated object has correct value');
