#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 26;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Filter';
use_ok( $class );

my $entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
my $filter = App::Goto::Dir::Data::Filter->new( 'name', 'description', '$visits > 1', {list => 'm'} );
is( ref $filter,                  $class,          'created filter object');
is( ref $filter->list_modes,  'App::Goto::Dir::Data::ValueType::Relations',          'list modes are relations');
is( $filter->list_modes->get_in('list'),   'm',    'list modes arrived from constructor');
is( $filter->name,                'name',          'filter name set by constructor is correct');
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

isnt(ref App::Goto::Dir::Data::Filter->new(),             $class, 'constructor need more arguments');
isnt(ref App::Goto::Dir::Data::Filter->new('n'),          $class, 'constructor need more than one argument');
isnt(ref App::Goto::Dir::Data::Filter->new('n','d'),      $class, 'constructor need more than two arguments');
isnt(ref App::Goto::Dir::Data::Filter->new('n','d', 'c'), $class, 'constructor need more than three arguments');
isnt(ref App::Goto::Dir::Data::Filter->new('n','d', 'c', 'm'), $class, 'fourth argument has to be hash');
isnt(ref App::Goto::Dir::Data::Filter->new(undef,'d', 'c', {}), $class, 'every argument has to have a value');

my $nf = App::Goto::Dir::Data::Filter->restate( $filter->state() ); # new filter
is( ref $nf,                      $class,          'cloned filter object');
is( $nf->name,                    'name',          'clone has right name');
is( $nf->description,      'description',          'clone got right description');

isnt(ref App::Goto::Dir::Data::Entry->new('dir'), $class,           'need a real directory to create entry object');

exit 0;
