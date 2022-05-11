#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 13;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use App::Goto::Dir::Data::Entry;
my $class = 'App::Goto::Dir::Data::List';

my $nameless = App::Goto::Dir::Data::List->new('dir');
is(ref $nameless, $class,           'created first simple entry');
is($nameless->dir, 'dir',           'got back directory');
is($nameless->name, '',             'got back name');

my $clone = $nameless->clone();
is(ref $clone, $class,              'clone has right class');
ok($nameless ne $clone,             'clone has different ref');
is($clone->dir, 'dir',              'clone has right directory');
$clone->rename('clone');
is($nameless->name, '',             'original didn\'t change name');
is($clone->name, 'clone',           'changed clones name');

my $named = App::Goto::Dir::Data::Entry->new($ENV{'HOME'}.'/dir', 'name');
is(ref $named, $class,              'created named entry');
is($named->dir, '~/dir',            'got back compact directory');
is($named->full_dir, $ENV{'HOME'}.'/dir', 'got back expanded directory');
is($named->name, 'name',            'got back name');
is($named->clone->name, 'name',     'got back name from clone');
