#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 84;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::List';
use_ok( $class );

my ($drive, $dir) = File::Spec->splitpath( __FILE__ );
my $adir = App::Goto::Dir::Data::ValueType::Directory::normalize_dir( $dir );

my $def_entry = App::Goto::Dir::Data::Entry->new( $ENV{'HOME'} );
my $h_entry = App::Goto::Dir::Data::Entry->new( $dir, 'here' );

my $l = App::Goto::Dir::Data::List->new();
is( ref $l,  '', 'need name to create entry list');
$l = App::Goto::Dir::Data::List->new('name');
is( ref $l,  '', 'need more than just name to create list');
$l = App::Goto::Dir::Data::List->new('name', 'description');
is( ref $l,  '', 'need more than just name and description to create list');
$l = App::Goto::Dir::Data::List->new('name', 'description', 0);
is( ref $l,  '', 'need more than just name, description and type to create list');
$l = App::Goto::Dir::Data::List->new('name', 'description', 0, []);
is( ref $l,  $class, 'created empty list');
is( $l->name,               'name', 'got empty lists name');
is( $l->set_name('set'),     'set', 'could set new name');
is( $l->name,                'set', 'got new name');
is( $l->description, 'description', 'got empty lists description');
is( $l->set_description('sed'), 'sed', 'could set new description');
is( $l->description,         'sed', 'got new description');
is( $l->is_special,              0, 'empty list is not special');
is( $l->entry_count,             0, 'empty list has zero members');
is( $l->is_position(1),          0, 'empty list has no member on position 1');
is( $l->is_position(-1),         0, 'empty list has no member on position -1');
is( $l->nearest_position(1),     0, 'empty list has only 0');
is( $l->get_entry_by_pos(1),            undef, 'empty list can not give you any element');
is( $l->get_entry_by_property('pos',1), undef, 'empty list can not give you element by universal getter');

my $report = $l->report();
is( $report =~ /set/,   1, 'list name is part of report');
is( $report !~ /sed/,   1, 'list description is not part of report');

is( $def_entry->list_pos->get('set'),              0, 'entry no position stored yet');
is( $l->insert_entry( $def_entry, 1 ),    $def_entry, 'could insert entry');
is( $l->entry_count,                               1, 'list has now one member');
is( int ($l->all_entries),                         1, 'all entries is a list of one');
is( $l->is_position(1),                            1, 'list has a member on position 1');
is( $l->is_position(-1),                           1, 'list has a member on position -1');
is( $l->is_position(2),                            0, 'list has no member on position 2');
is( $l->is_position(-2),                           0, 'list has no member on position -2');
is( $l->is_position(0),                            0, 'list has no member on position zero');
is( $def_entry->list_pos->get('set'),              1, 'entry has correct position stored');
is( $l->nearest_position(5),                       1, 'nearest position of 5 is one');
is( $l->nearest_position(-5),                      1, 'nearest position of -5 is one');
is( $l->get_entry_by_pos(1),              $def_entry, 'new entry is at position one');
is( $l->get_entry_by_pos(-1),             $def_entry, 'new entry is at position minus one');
is( $l->get_entry_by_pos(2),                   undef, 'no entry is at position two');
is( $l->get_entry_by_pos(-2),                  undef, 'no entry is at position minus two');
is( $l->get_entry_by_pos(0),                   undef, 'no entry is at position zero');
is( $l->get_entry_by_property('pos', 1),  $def_entry, 'got new entry by property getter');
is( $l->get_entry_by_property('dir', '~'),$def_entry, 'got new entry by dir');
is( $l->get_entry_by_property('os', '~'),      undef, 'universal getter can handle bad property name');

is( $l->remove_entry( 2 ),            undef, 'remove entry with bad index');
is( $l->remove_entry( 0 ),            undef, 'remove entry with no index');
is( $l->remove_entry( -1 ),      $def_entry, 'remove entry with only index');
is( $def_entry->list_pos->get('set'),     0, 'entry no position stored again');
is( $l->entry_count,                      0, 'list has no member again');

is( $l->insert_entry( $def_entry, -2 ),    $def_entry, 'insert entry at wrong position but works anyway');
is( $l->get_entry_by_pos(1),               $def_entry, 'new entry is at only possible position');
is( $l->insert_entry( $h_entry, -2 ),        $h_entry, 'insert second entry with negativ position index');
is( $l->entry_count,                                2, 'list has now two member');
is( $def_entry->list_pos->get('set'),               2, 'first entry got pushed on second position');
is( $h_entry->list_pos->get('set'),                 1, 'second entry is on first position');
is( $l->is_position(2),                             1, 'list has now member on position 2');
is( $l->is_position(-2),                            1, 'list has now member on position -2');
is( $l->is_position(3),                             0, 'list has no member on position 3');
is( $l->is_position(-3),                            0, 'list has no member on position -3');
is( $l->get_entry_by_pos(-1),              $def_entry, 'got second entry by negative index');
is( $l->get_entry_by_pos(-2),                $h_entry, 'got first entry by negative index');
is( $l->get_entry_by_property('dir', '~'), $def_entry, 'got second entry by dir');
is( $l->get_entry_by_property('dir', $adir), $h_entry, 'got second entry by full dir');
is( $l->get_entry_by_property('dir', $dir),  $h_entry, 'got second entry by relative dir');
is( $l->get_entry_by_property('name','here'),$h_entry, 'got second entry by name');

$report = $l->report();
is( $report =~ /set/,    1, 'list name is part of report');
is( $report !~ /sed/,    1, 'list description is not part of report');
is( $report =~ /here/,   1, 'entry name is part of report');
is( $report =~ /\[01\]/, 1, 'first entry number is part of report');
is( $report =~ /\[02\]/, 1, 'second entry number is part of report');
is( $report !~ /\[03\]/, 1, 'no third entry number is part of report');

$l = App::Goto::Dir::Data::List->new('set', 'description', 1, [$h_entry, $def_entry]);
is( ref $l,                                  $class, 'restated poulated list');
is( $l->is_special,                               1, 'restated list is special');
is( $l->entry_count,                              2, 'list has two members');
is( $l->get_entry_by_pos(1),               $h_entry, 'got first entry by positive index');
is( $l->get_entry_by_pos(2),             $def_entry, 'got second entry by positive index');
is( $l->remove_entry( 1 ),                 $h_entry, 'remove first entry');

$l = App::Goto::Dir::Data::List->new('set', 'description', 1, [$h_entry, $def_entry]);
is( ref $l,                                   $class, 'restated poulated list, with deleted member');
is( $l->entry_count,                               1, 'ignored deleted entry');
is( $l->get_entry_by_pos(1),              $def_entry, 'right entry remained');
is( $l->insert_entry( $def_entry, 1 ),         undef, 'can not add entry twice');
is( $l->has_entry( $def_entry),                    1, 'default entry is member of list');
is( $l->has_entry( $h_entry),                      0, 'home entry is not member of list');

is( $l->empty_list( ),                             1, 'list had one member');
is( $l->empty_list( ),                             0, 'list is now empty');
is( $l->entry_count,                               0, 'list has no member');

is( $def_entry->list_pos->is_member_of('set'),     0, 'entry is no longer subscribed to list');

exit 0;
