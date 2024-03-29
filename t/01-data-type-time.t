#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 25;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::TimeStamp';

use_ok( $class );

my $obj = App::Goto::Dir::Data::ValueType::TimeStamp->new();
is( ref $obj, $class, 'created first object');
is( $obj->get,     0, 'default value is zero');

$obj->set(1);
my $t = time;
is( abs(time - $t) < 5,  1, 'updated just now');
$obj->set(0);
is( $obj->get,           0, 'could reset value');
is( $obj->is_empty,      1, 'empty predicate works');

$obj->set(1);
$t = time;
is( $obj->is_empty,                  0, 'got valid time stamp again');
is( $obj->is_older_then_age(0),      0, 'time stamp is newer than beginning of period');
is( $obj->is_older_then_period(10),  0, 'time stamp is newer than 10 seconds');
is( $obj->age_in_days() < 1,         1, 'time stamp is newer one day');

my $value = $obj->get;
is( $value > 1,                      1, 'getter brings a positive value');
$obj->set(0);
is( $obj->is_older_then_age(10),     1, 'time stamp is older than after beginning of period');
is( $obj->is_older_then_period(10),  1, 'time stamp is older than 10 seconds');
is( $obj->age_in_days() > 18250,     1, 'time stamp is older than 50 years');
is( $obj->format(0,0),    '01.01.1970', 'correct time string, date only, human readable order');
is( $obj->format(),       '01.01.1970', 'format arg defaults are correct');
is( $obj->format(0,1),    '1970.01.01', 'correct time string, date only, sortable order');
is( $obj->format(1),      '01.01.1970  01:00:00', 'correct time string, with time, human readable order');
is( $obj->format(1,1),    '1970.01.01  01:00:00', 'correct time string, with time, sortable order');

$obj = App::Goto::Dir::Data::ValueType::TimeStamp->new(1);
is( $obj->is_empty,      0, 'created none empty time stamp');
$obj = App::Goto::Dir::Data::ValueType::TimeStamp->new(0);
is( $obj->is_empty,      1, 'created explicitly empty time stamp');
$obj->update;
is( $obj->is_empty,      0, 'time stamp was created via update');
my $state = $obj->state;
is( $obj->get,      $state, 'could retrieve inner state');
my $nobj = App::Goto::Dir::Data::ValueType::TimeStamp->restate($state);
is( ref $nobj, $class, 'recreated object via restate');
is( $obj->get,   $obj->get, 'restated object has correct value');

exit 0;
