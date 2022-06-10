use v5.18;
use lib 'lib';
use Benchmark;
use Cwd;
use FindBin;
use File::UserConfig;

my ($t, $cwd);
BEGIN {
    $t = Benchmark->new();
    $cwd = Cwd::cwd();
    chdir $FindBin::Bin;
}
use App::Goto::Dir;
# $configdir = File::UserConfig->configdir;


my $app = App::Goto::Dir->new( $cwd );

#my $file = "goto_dir_config.yml";
#my $config = App::Goto::Dir::Config::load();
#my $data = App::Goto::Dir::Data->new( $config );
#App::Goto::Dir::Parser::init( $config );
#$data->add_entry( '~/code/perl/projekt/App-Goto-Dir', 'gt' );
#$data->add_entry( '~/code/perl/projekt', 'p' );
#say $data->delete_entry( 'all', 'p' );
#$data->write( $config );


#say App::Goto::Dir::Command::run('help');
#say App::Goto::Dir::Command::run('help', 'basics');
#say App::Goto::Dir::Command::run('help', 'commands');
#say App::Goto::Dir::Command::run('help', 'install');
#say App::Goto::Dir::Command::run('help', 'version');
#say App::Goto::Dir::Command::run('help', '--add');
#say App::Goto::Dir::Command::run('help', '--delete');
#say App::Goto::Dir::Command::run('help', '--undelete');
#say App::Goto::Dir::Command::run('help', '--remove');
#say App::Goto::Dir::Command::run('help', '--move');
#say App::Goto::Dir::Command::run('help', '--copy');
#say App::Goto::Dir::Command::run('help', '--name');
#say App::Goto::Dir::Command::run('help', '--dir');
#say App::Goto::Dir::Command::run('help', '--redir');
#say App::Goto::Dir::Command::run('help', '--script');
#say App::Goto::Dir::Command::run('help', '--list');
#say App::Goto::Dir::Command::run('help', '--sort');
#say App::Goto::Dir::Command::run('help', '--list-special');
#say App::Goto::Dir::Command::run('help', '--list-lists');
#say App::Goto::Dir::Command::run('help', '--list-add');
#say App::Goto::Dir::Command::run('help', '--list-delete');
#say App::Goto::Dir::Command::run('help', '--list-name');
#say App::Goto::Dir::Command::run('help', '--list-description');
#say App::Goto::Dir::Command::run('help', '--help');

#say App::Goto::Dir::Command::run('list-special');
#say App::Goto::Dir::Command::run('list-lists');
#say App::Goto::Dir::Command::run('list-add', 'a', 'test list');
#say App::Goto::Dir::Command::run('list-add', 'use', 'test list');


#say App::Goto::Dir::Command::run('list-name', 'a', 'b');
#say App::Goto::Dir::Command::run('list-lists');
#say App::Goto::Dir::Command::run('list-delete', 'b');
#say App::Goto::Dir::Command::run('list-lists');
#say App::Goto::Dir::Command::run('list-add',  '@all', 'all');
#say App::Goto::Dir::Command::run('list-delete', '@all');
#say App::Goto::Dir::Command::run('add', '~/Dokumente/vortrag', 'v');
#say App::Goto::Dir::Command::run('list','@all', '@new', '@bin', '@named', '@stale', 'use');
#say App::Goto::Dir::Command::run('move', 'use', 'p', 'idle');
#say App::Goto::Dir::Command::run('add', '~/Dokumente/vortrag');
#say App::Goto::Dir::Command::run('sort','position');
#say App::Goto::Dir::Command::run('list','@all', '@new', 'use', '@bin');
#say App::Goto::Dir::Config::reset();
#say App::Goto::Dir::Command::run('sort', 'vis');
#say App::Goto::Dir::Command::run('list', '@all');

#say App::Goto::Dir::Parse::is_dir('/');
#say App::Goto::Dir::Parse::is_position('4');

#say App::Goto::Dir::Command::run('list-lists');
#say App::Goto::Dir::Command::run('list-special');


my $data = $app->{'data'};
my $all = $data->get_special_lists('all');
my $pos = $all->pos_from_name('');

my $args = App::Goto::Dir::Parse::args("");
say int @$args;
for my $arg (@$args){
    print " - ";
    if (ref $arg){ print "$_" for @$arg }
    else         { print $arg }
    say '';
}

say '   run goto test in ', sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';


$app->exit();
__END__

all: add copy

#say App::Goto::Dir::Data::Entry::_format_time_stamp(time );

