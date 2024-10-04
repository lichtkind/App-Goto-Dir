#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 30;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::Relation';

use_ok( $class );

my $obj = App::Goto::Dir::Data::ValueType::Relation->new();
is( ref $obj,                $class, 'Created first object');
is( int($obj->list_sets()),       0, 'member of no list');
is( $obj->is_in_set('A'),         0, 'not in list A');
is( $obj->get_in('A'),            0, 'no position in list A');
is( $obj->set_in('A', 1),     undef, 'no position in list A');
is( $obj->remove_set('A'),    undef, 'could not remove from list A');
is( $obj->add_set('A', 1),        1, 'add position 1 to list A');
is( $obj->is_in_set('A'),         1, 'now in list A');
is( int($obj->list_sets()),       1, 'member of one list');
is( ($obj->list_sets())[0],     'A', 'name of list');
is( $obj->get_in('A'),            1, 'correct position in list A');
is( $obj->set_in('A', 5),         5, 'change position in list A');
is( $obj->remove_set('A'),       5, 'could not remove from list A');
is( int($obj->list_sets()),       0, 'member of no list');
is( $obj->add_set('A', 2),       2, 'added to list A again');
is( $obj->add_set('B', 3),       3, 'added to second list B');
is( $obj->get_in('A'),            2, 'position in list A');
is( $obj->get_in('B'),            3, 'position in list B');
is( int($obj->list_sets()),       2, 'member in two lists');
is( (sort $obj->list_sets())[0],  'A', 'name of first list');
is( (sort $obj->list_sets())[1],  'B', 'name of second list');

my $state = $obj->state;
is( ref $state,     'HASH', 'state is HASH ref');
is( int(keys %$state),   2, 'state has 2 pairs');
is( $state->{'A'},       2, 'state has correct A list position 2');
is( $state->{'B'},       3, 'state has correct B list position 3');

my $nobj = App::Goto::Dir::Data::ValueType::Relation->restate( $state );
is( ref $nobj, $class, 'recreated object via restate');
is( $nobj->get_in('A'),             2, 'position in list A');
is( $nobj->get_in('B'),             3, 'position in list B');
is( int($nobj->list_sets()),     2, 'member in two lists');

exit 0;
