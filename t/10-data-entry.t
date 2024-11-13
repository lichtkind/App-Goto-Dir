#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 55;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Entry';
use_ok( $class );

isnt(ref App::Goto::Dir::Data::Entry->new('dir'), $class,           'need a real directory to create entry object');
my $entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
is( ref $entry,   $class,              'created entry object');
is( $entry->days_old,            0,    'age is zero, entry was just created');

is( $entry->visits,                 0, 'entry was not yet visited');
is( $entry->get_property('visits'), 0, 'get visits count from universal getter');
is( $entry->days_not_visited,   -1,    'not last visit time stamp');
is( $entry->is_expired(1),       0,    'not a deleted entry');
is( $entry->dir,               '~',    'entry has a directory');
is( $entry->is_broken,           0,    'entry directory exists');
is( $entry->name,               '',    'entry has no name');
is( $entry->description,        '',    'entry has no description');
is( $entry->script,             '',    'entry has no script');
is( $entry->note,               '',    'entry has no note');
is( $entry->visit_dir,           1,    'visit entry');
is( $entry->visits,              1,    'entry was visited once');
is( $entry->days_not_visited,    0,    'last visit was just now');
is( $entry->visit_dir,           2,    'visit entry again');
is( $entry->visits,              2,    'entry count still consistent');
is( $entry->is_deleted,          0,    'entry is not deleted');
is( $entry->is_expired(0),       0,    'entry is not expired, even if there is no grace period');
is( ($entry->undelete == 0),     1,    'could not undelete entry');
is( ($entry->delete > 0),        1,    'could delete entry');
is( $entry->is_deleted,          1,    'entry is now deleted');
is( ($entry->undelete > 0),      1,    'could undelete entry');
is( $entry->is_deleted,          0,    'entry is undeleted --');
is( $entry->get_property('delete_time'), 0, 'delete time via universal getter');


is( ref $entry->list_positions, 'App::Goto::Dir::Data::ValueType::Relations',  'got access to list position object');
is( $entry->is_in_list('all'),   0,  'is not in unknown list');
$entry->list_positions->add_set('all', 5);
is( $entry->is_in_list('all'),   1,  'is in known list');
is( $entry->list_positions->get_in('all'),  5,  'got righ list position');

is( $entry->rename('home'),  'home',   'could rename entry');
is( $entry->name,            'home',   'new entry name retrieved');
is( $entry->get_property('name'),     'home',   'entry name retrieved via universal getter');

is( $entry->redescribe('first'),  'first',   'could change description');
is( $entry->description,          'first',    'new entry description retrieved');
is( $entry->get_property('description'), 'first',   'entry description retrieved via universal getter');

is( $entry->notate('remark'),         'remark', 'could note a word');
is( $entry->note,                     'remark', 'entry has now a note');
is( $entry->get_property('note'),     'remark', 'entry note retrieved via universal getter');

is( $entry->rescript('bang();'),     'bang();', 'could change entry script');
is( $entry->script,                  'bang();', 'entry has now a script');
is( $entry->get_property('script'),  'bang();', 'entry script retrieved via universal getter');

my ($drive, $dir) = File::Spec->splitpath( __FILE__ );
my $ndir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );
my $edir = App::Goto::Dir::Data::ValueType::Directory::expand_home_dir( $ndir );

is( $entry->redirect($ndir),    $ndir, 'could change directory of entry');
is( $entry->dir,                $ndir, 'entry has now a different directory');
is( $entry->get_property('dir'),$edir, 'entry dir retrieved via universal getter');


is( $entry->is_property('diro'), 0, 'diro is not an available property');
is( $entry->is_property('dir'),  1, 'dir is an available property');
is( $entry->is_property('age'),  1, 'dir is an available property');

my $centry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'}, 'name', 'description' );
is( $centry->name,               'name',           'entry a name via constructor');
is( $centry->description,        'description',    'entry has a description via constructor');

is( $centry->cmp_property('dir', $entry),        -1, 'first entry has shorter subdir');
is( $entry->cmp_property('visits', $centry),      1, 'first entry has more visits');
is( $entry->cmp_property('delete_time', $centry), 0, 'both entry have no delete time');

my $bentry = App::Goto::Dir::Data::Entry->new( 'bentry' );
is( ref $bentry,           '',    'can not create entry with broken dir');

exit 0;
