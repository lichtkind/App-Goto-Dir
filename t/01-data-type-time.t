#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 35;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
my $class = 'App::Goto::Dir::Data::ValueType::TimeStamp';

use_ok( $class );

my $stamp = App::Goto::Dir::Data::ValueType::TimeStamp->new();
is( ref $stamp,     $class, 'created first object with no constructor argument');
is( $stamp->get,         0, 'default value is zero');
is( $stamp->is_empty,    1, 'stamp is empty');
is( $stamp->age,         0, 'has no age');
is( $stamp->age_in_days, 0, 'has no age, counted in days');
is( $stamp->is_older_then_stamp(22), 0,  'can not tell if older than certain time point when stamp is empty');
is( $stamp->is_older_then_period(22), 0, 'can not tell if older than certain time period if stamp is empty');
is( $stamp->format(),              '01.01.1970',           'right default format (date only, human readable)');
is( $stamp->format('time'),        '01.01.1970  01:00:00', 'right format with date and time');
is( $stamp->format(0,1),           '1970.01.01',           'sortable date format');
is( $stamp->format('time','sort'), '1970.01.01  01:00:00', 'right format with date and time');

is( $stamp->set(1),        1, 'changed value via setter');
is( $stamp->get,           1, 'got new value correctly');
is( $stamp->is_empty,      0, 'stamp is no longer empty');
is( $stamp->age > 1_000_000_000, 1, 'has age');
is( $stamp->age_in_days > 20_000, 1, 'has age, counted in days');
is( $stamp->is_older_then_stamp(22), 1,  'stamp is older than old time point');
is( $stamp->is_older_then_stamp(0),  0,  'stamp is newer than beginning of computer counting');
is( $stamp->is_older_then_stamp(App::Goto::Dir::Data::ValueType::TimeStamp::_now()), 1, 'stamp is much old then now');
is( $stamp->is_older_then_period(22), 1, 'stamp is older then some short seconds ago');

my $t = $stamp->update();
is( abs(time - $t) < 5,    1, 'updated just now');
is( $stamp->get,            $t, 'got new value correctly');
is( $stamp->is_empty,        0, 'stamp is after update not empty');
is( ($stamp->age < 5),       1, 'stamp is very young after update');
is( $stamp->age_in_days < 1, 1, 'stamp has age of zero days');
is( $stamp->is_older_then_stamp(0),    0, 'time stamp is newer than beginning of period');
is( $stamp->is_older_then_stamp(22),   0, 'time stamp is newer than an very old');
is( $stamp->is_older_then_period(10),  0, 'time stamp is newer than 10 seconds');
is( $stamp->clear,          $t, 'got old value the reset to zero');
is( $stamp->get,             0, 'new value is zero after reset');
is( $stamp->is_empty,        1, 'stamp is empty again');

is( $stamp->set($t),        $t, 'reset to recent value');
my $state = $stamp->state;
my $nobj = App::Goto::Dir::Data::ValueType::TimeStamp->restate($state);
is( ref $nobj,          $class, 'recreated object via restate');
is( $nobj->get,             $t, 'restated object has correct value');

exit 0;
