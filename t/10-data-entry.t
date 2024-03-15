#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 30;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Entry';
use_ok( $class );

isnt(ref App::Goto::Dir::Data::Entry->new('dir'), $class,           'need a real directory to create entry object');
my $obj = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
is( ref $obj,   $class,              'created entry object');
is( $obj->age,       0,              'entry was just created');
is( $obj->visits,    0,              'entry was not yet visited');
is( $obj->days_not_visited,   -1,    'not last visit time stamp');
is( $obj->is_expired(1),       0,    'not a deleted entry');
is( $obj->dir,                '~',   'entry has a directory');
is( $obj->name,               '',    'entry has no name');
is( $obj->script,             '',    'entry has no script');
is( $obj->note,               '',    'entry has no note');
is( $obj->visit_dir,           1,    'visit entry');
is( $obj->visits,              1,    'entry was visited once');
is( $obj->days_not_visited,    0,    'last visit was just now');
is( $obj->visit_dir,           2,    'visit entry again');
is( $obj->visits,              2,    'entry count still consistent');
is( ref $obj->list_pos, 'App::Goto::Dir::Data::ValueType::Position',  'got access to list position object');
is( $obj->rename('home'),  'home',   'could rename entry');
is( $obj->name,            'home',   'entry name retrieved');
is( $obj->get('name'),     'home',   'entry name retrieved via universal getter');
is( $obj->notate('remark'),'remark', 'could note a word');
is( $obj->note,            'remark', 'entry has now a note');
is( $obj->get('note'),     'remark', 'entry note retrieved via universal getter');
is( $obj->edit('bang();'), 'bang();','could change entry script');
is( $obj->script,          'bang();','entry has now a script');
is( $obj->get('script'),   'bang();','entry script retrieved via universal getter');

my ($dive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );

is( $obj->redirect($adir),    $adir, 'could change directory of entry');
is( $obj->dir,                $adir, 'entry has now a different directory');
is( $obj->get('dir'),         $adir, 'entry dir retrieved via universal getter');
is( $obj->delete() > 1,           1, 'could delete entry, since it was not deleted yet');


exit 0;
