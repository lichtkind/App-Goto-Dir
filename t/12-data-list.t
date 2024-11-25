#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 84;
use FindBin qw( $RealBin );
use File::Spec;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::List';
use_ok( $class );

my ($volume, $directories, $file) = File::Spec->splitpath( $RealBin );
my @dir_part = grep {$_} File::Spec->splitdir( $directories );
my $path = '';
my @dir = map {$path = File::Spec->catdir( $path, $_ ); $path } @dir_part;
my $nr = 1;
my @entry = map { App::Goto::Dir::Data::Entry->new( $_, $nr++ ) } @dir;


is( ref App::Goto::Dir::Data::List->new(),       '', 'constructor needs arguments');
is( ref App::Goto::Dir::Data::List->new('name'), '', 'needs more than just a name');
is( ref App::Goto::Dir::Data::List->new('name', 'description'), '', 'and a description');
is( ref App::Goto::Dir::Data::List->new('name', 'description', []), '', 'and and empty element list');
is( ref App::Goto::Dir::Data::List->new('', 'description', [], []), '', 'need an actual name');
is( ref App::Goto::Dir::Data::List->new('name', '', [], []), '', 'need an actual description');

my $empty = App::Goto::Dir::Data::List->new('name', 'description', [], []);
is( ref $empty,                             $class, 'four arguments are enough');
is( $empty->name,                           'name', 'got list name given via description');
is( $empty->rename('rename'),             'rename', 'changed list name');
is( $empty->name,                         'rename', 'got new list name');
is( $empty->description,             'description', 'got list description given via constructor');
is( $empty->redescribe('redescribe'), 'redescribe', 'changed list description');
is( $empty->description,              'redescribe', 'got new list description');
is( $empty->sorting_order,              'position', 'got default sorting_order since constructor got none');
is( $empty->reverse_sorting_order, 'reverse position', 'reversed sorting order');
is( $empty->reverse_sorting_order,      'position', 'reversed sorting order back');
is( $empty->set_sorting_order('reverse dir'), 'reverse dir', 'could change sorting order');
is( $empty->reverse_sorting_order,           'dir', 'reversed custom sorting order');
is( $empty->set_sorting_order('nom'),        undef, 'could not set unknown sorting order');
is( $empty->set_sorting_order('reverse pos'), undef, 'could not set unknown sorting order in reverse');
is( $empty->set_sorting_order('rev position'), undef, 'could not use unknown sorting order prefix');

is( $empty->entry_count, 0, 'list is empty');
is( int( $empty->all_filter ), 0, 'list has no filter');


exit 0;
