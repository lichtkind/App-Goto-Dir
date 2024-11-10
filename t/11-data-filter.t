#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 11;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Filter';
use_ok( $class );


exit 0;

__END__

is( ref $entry,   $class,              'created entry object');
is( $entry->days_old,            0,    'age is zero, entry was just created');

is( $entry->visits,                 0, 'entry was not yet visited');
is( $entry->get_property('visits'), 0, 'get visits count from universal getter');
is( $entry->days_not_visited,   -1,    'not last visit time stamp');
is( $entry->is_expired(1),       0,    'not a deleted entry');
is( $entry->dir,               '~',    'entry has a directory');
