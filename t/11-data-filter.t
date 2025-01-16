#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 34;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Filter';
use_ok( $class );

isnt( ref App::Goto::Dir::Data::Filter->new(),                          $class, 'constructor needs arguments');
isnt( ref App::Goto::Dir::Data::Filter->new('$visits > 1'),             $class, 'needs more than just a code');
isnt( ref App::Goto::Dir::Data::Filter->new('$visits > 1', 'name'),     $class, 'needs more than just a code and name');
isnt( ref App::Goto::Dir::Data::Filter->new( undef, 'name', 'descr'),   $class, 'code has to be defined');
isnt( ref App::Goto::Dir::Data::Filter->new( [], 'name', 'descr'),      $class, 'code has to be string');
isnt( ref App::Goto::Dir::Data::Filter->new('1', undef, 'descr'),       $class, 'name has to be defined');
isnt( ref App::Goto::Dir::Data::Filter->new('1', [], 'descr'),          $class, 'name has to be a string');
isnt( ref App::Goto::Dir::Data::Filter->new('1', 'name', undef),        $class, 'description has to be defined');
isnt( ref App::Goto::Dir::Data::Filter->new('1', 'name', []),           $class, 'description has to be a string');
isnt( ref App::Goto::Dir::Data::Filter->new('jam > 1', 'name', 'descr'), $class, 'code has to compile');
isnt( ref App::Goto::Dir::Data::Filter->new('$jam > 1', 'name', 'descr'), $class, 'variable in code is no entry property');


my $entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'}, 2 );
my $filter = App::Goto::Dir::Data::Filter->new( '$visits > 1', 'visits', 'description' );
is( ref $filter,                  $class,          'created filter object');
is( ref $filter->list_modes,  'App::Goto::Dir::Data::ValueType::Relations',          'list modes are relations');
is( $filter->list_modes->get_in('list'),  0,       'no list modes set yet');
is( $filter->name,              'visits',          'filter name set by constructor is correct');
is( $filter->description,  'description',          'got filter description set by constructor');
is( $filter->rename('rename'),  'rename',          'new filter name correct');
is( $filter->name,              'rename',          'got new name by name getter');
is( $filter->redescribe('re'),      're',          'new description set by setter');
is( $filter->description,           're',          'got new description by getter');
is( $filter->report,        'rename: re',          'altered filter report correct');
is( $filter->rename('name'),      'name',          'set name back');
is( $filter->redescribe('description'), 'description', 'new description set by setter');
is( $filter->report, 'name: description',          'filter report correct');

is( $filter->accept_entry($entry),     0,          'entry is not visited, so rejected by filter');
$entry->visit_dir;
$entry->visit_dir;
is( $filter->accept_entry($entry),     1,          'entry is now visited, so accepted by filter');

my $name_filter = App::Goto::Dir::Data::Filter->new( '$name == 2', 'name', 'description' );
is( $name_filter->accept_entry($entry),  1,        'entry has right name');
$entry->rename(3);
is( $name_filter->accept_entry($entry),  0,        'entry has no longer right name');
is( $name_filter->report(10), 'name: desc',        'filter produced report with wanted length');


my $nf = App::Goto::Dir::Data::Filter->restate( $filter->state() ); # new filter
is( ref $nf,                      $class,          'cloned filter object');
is( $nf->name,                    'name',          'clone has right name');
is( $nf->description,      'description',          'clone got right description');

isnt(ref App::Goto::Dir::Data::Entry->new('dir'), $class,           'need a real directory to create entry object');

exit 0;
