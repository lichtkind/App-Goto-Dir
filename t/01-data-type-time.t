#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 51;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use App::Goto::Dir::Data::Entry;
my $class = 'App::Goto::Dir::Data::Entry';

my $empty = App::Goto::Dir::Data::Entry->new();
is(ref $empty, '',                 'need at least a directory');

my $nameless = App::Goto::Dir::Data::Entry->new('dir');
is(ref $nameless, $class,           'created first simple entry');
is($nameless->dir, 'dir',           'directory getter works');
is($nameless->name, '',             'has no name');
is($nameless->script, '',           'and no script');
ok($nameless->create_time,          'has created time stamp');
is($nameless->visit_time, 0,        'was not visited yet');
is($nameless->visit_count, 0,       'so no visits counted');
is($nameless->delete_time, 0,       'was not deleted');


my $clone = $nameless->clone();
is(ref $clone, $class,              'could clone the entry');
ok($nameless ne $clone,             'clone has different ref');
is($clone->dir, 'dir',              'clone has right directory');
$clone->redirect('cdir');
is($nameless->dir, 'dir',           'original is unaffected');
is($clone->dir, 'cdir',             'clone entry has new directory');

is($clone->name, '',                'clone got no name from original');
$clone->rename('clone');
is($nameless->name, '',             'original didn\'t change name');
is($clone->name, 'clone',           'changed clones name');

is($clone->script, '',              'clone got no script from original');
$clone->edit('script');
is($nameless->script, '',           'original didn\'t change script');
is($clone->script, 'script',        'changed clones script');

is($clone->create_time, $nameless->create_time,  'clone got same create time as original');
is($clone->visit_time,  $nameless->visit_time,   'clone got same visit time as original');
is($clone->visit_count, $nameless->visit_count,  'clone got same visit count as original');
is($clone->delete_time, $nameless->delete_time,  'clone got same delete time as original');

is($clone->visit, 'cdir',           'visited ones clone directory');
is($clone->visit_count, 1,          'one visit so far');
ok($clone->create_time,             'clone has now have visit time stamp');
is($nameless->visit_time, 0,        'original still was not visited');
is($nameless->visit_count, 0,       'so no visits counted');

ok($clone->delete,                  'could delete clone');
ok($clone->delete_time,             'clone has now have delete time stamp');
ok($clone->is_deleted,              'clone is deleted');
is($nameless->delete_time, 0,       'original unaffected');
ok(!$nameless->is_deleted,          'original is not deleted');
ok($nameless->delete,               'deleted original');
is($clone->undelete, 0,             'reversed deletion of clone');
ok(!$clone->is_deleted,             'clone is no longer deleted');
ok($nameless->is_deleted,           'original is still deleted (unaffected from undelete)');

is(int($nameless->member_of_lists), 0,    'entry is part of no list');
is(int($clone->member_of_lists), 0,       'clone also');
$clone->add_to_list('a',1);
is(int($nameless->member_of_lists), 0,    'entry is still part of no list');
is(int($clone->member_of_lists), 1,       'clone is in one list');
is($clone->get_list_pos('a'), 1,          'clone has a list pos');
is($clone->remove_from_list('a'), 1,      'clone was removed from list');
is($clone->get_list_pos('a'), undef,      'clone has no longer this list pos');
is(int($clone->member_of_lists), 0,       'clone is in no lists');


my $named = App::Goto::Dir::Data::Entry->new($ENV{'HOME'}.'/dir', 'name');
is(ref $named, $class,              'created named entry');
is($named->dir, '~/dir',            'got back compact directory');
is($named->full_dir, $ENV{'HOME'}.'/dir', 'got back expanded directory');
is($named->name, 'name',            'got back name');
is($named->clone->name, 'name',     'got back name from clone');

#say App::Goto::Dir::Data::Entry::reformat_time_stamp($named->create_time, 'd.m.y  t');

exit 0;
