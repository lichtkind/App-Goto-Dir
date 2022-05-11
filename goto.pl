#!/usr/bin/perl
use v5.18;
use lib 'lib';
use warnings;
no warnings  qw/experimental::smartmatch/;
use feature qw/switch/;
use Benchmark;
use File::Spec;
use FindBin;
use Cwd;
our $cwd = Cwd::cwd();
my $PROGRAM     = 'App::Goto::Dir';
my $VERSION     =  0.8;
my $config_file = 'goto_dir_config.yml';

my $t = Benchmark->new();

chdir $FindBin::Bin;
require App::Goto::Dir::Parser;
require App::Goto::Dir::Data;

die "config file $config_file not found" unless -r $config_file;
(my $config) = YAML::LoadFile( $config_file );

die "no data file defined in config file $config_file" unless exists $config->{'file'}{'data'} or exists $config->{'file'}{'backup'};
unless (exists $config->{'file'}{'data'}) {
    $config->{'file'}{'data'} = $config->{'file'}{'backup'};
    $config->{'file'}{'backup'} = $config->{'file'}{'backup'}.'.bak';
}
die "neither data file $config->{file}{data} nor backup file $config->{file}{backup} can be loaded" unless -r $config->{'file'}{'data'} or -r $config->{'file'}{'backup'};
#if (exists $config->{'file'}{'data'}){
#    die "data file $config->{file}{data} not found" unless -r $config->{'file'}{'data'};
#} else {
#    die "data backup file $config->{file}{backup} not found" unless -r $config->{'file'}{'backup'};
#    $config->{'file'}{'data'} = $config->{'file'}{'backup'};
#    $config->{'file'}{'backup'} = $config->{'file'}{'backup'}.'.bak';
#}

my $arg_sep = '['.$config->{'syntax'}{'argument_separator'}.']';
my $cmd_pre = '[,:->]';
my $char = '[a-zA-Z0-9]';


my $data = App::Goto::Dir::Data->new( $config->{'file'}{'data'} );

$data->display_current_list();
print "the code took:",timestr(timediff(Benchmark->new(), $t)),"\n";

help();

sub help {
	my $what = shift;
	if (not $what or $what eq 'txt'){
        say <<EOH;

          Help of          App::Goto::Dir        Version $VERSION

  Command line tool gt (short for goto) changes the working dir like cd,
  to a set of stored locations you don't have to write as a full path.
  These dir's are organized by lists, and can be adressed via their
  list position (<pos>), or an user given short name (<name>).
  <ID> (dir entry identifier) means <pos> or <name>.

  Use 'gt <ID>' to switch dir or open the interactive mode via 'gt' and
  select the dir there. Both ways can also be used to administer lists.
  Syntax and output of all commands will be the same.
  
  For instance add ~/code/perl/goto under the name gd do either type
  'gt -add gd:\~/code/perl/goto' or open interactive mode via 'gt'
  and write '-add gd:\~/code/perl/goto' there. 
  Then just press <Enter> again to exit the interactive mode.

  Every command has a long name and a configurable shortcut.
  It is usually the first letter of the full name. 
  Sorting criteria have shortcuts too.
  
  In order to makte gt operational, add to the shellrc the following line:

  function gt() { perl ~/../goto.pl $@ cd \$(cat ~/../last_choice) }
 
EOH
	}
	if (not $what or $what eq 'cmd'){
        say <<EOH;

  syntax rules:

 <dir>   directory path, starts with / or ~/, defaults to dir gt is called from
 <name>  name of list entry, only word char (\\w), first char has to be a letter
 <lname> name of a list, defaults to current list when omitted
 <pos>   list position, first is 1, last is -1 (default)
 <ID> =  <name> or <pos> or #<pos> or <name>#<pos> (entry identifier)
 -       starting character of any command in long (-add) or short form (-a)
 #       (read number) separates <lname> and <pos> in full adress of an entry
 :       follows <name>, to assign it to an entry (see -add -name)
 >       separates an entry (left) and its destination (right) (-add -move -copy)
 <Space> has to separate long commands and data, allowed around > and after :


  commands for changing directory:

 <name> .  .  .  go to dir with <name> (right beside <pos> in list)
 <pos>  .  .  .  go to dir listed on <pos> (in []) of current list
 <lname>#<pos>   go to directory at <pos> in list <lname>
 <ID>/sub/dir .  go to subdirectory of a stored dir
 _   .  .  .  .  go to dir gone to last time
 -   .  .  .  .  go to dir gone previously (like cd-)
 <Enter>   .  .  exit interactive mode and stay in current dir
 
  
  display commands:

 -list  .  .  .  .  display current list (not needed in interactive)
 -list <lname>   .  set <lname> as current list and display it
 -list <lpos> .  .  switch to list on <lpos> in the list of lists
 -list-list   .  .  display available list names (long for -l-l)
 -sort position  .  sort displayed list by position (default = -sort)
 -sort name   .  .  change sorting criterion to <name> (long for -sn)
 -sort visits .  .  sort by number of times gone to dir (a.k.a. -sv)
 -sort last_visit   sort by time of last visit (earlier first, -sl)
 -sort created   .  sort by time of dir entry creation (a.k.a -sc)
 -sort dir .  .  .  sort by dir path (a.k.a. -sort d)
 -help  .  .  .  .  long help = intro text + commands overview
 -help txt .  .  .  intro text
 -help cmd .  .  .  display list of commands
 -help <command> .  detailed help for one command

  
  commands for managing list entries:

 -add <name>:<dir> > <ID>   add <dir> under <name> on <pos> as defined by <ID>
 -del <ID>   .  .  .  .  .  delete directory entry as defined by <ID>
 -name <name>:<ID> .  .  .  (re-)name entry, resolve conflict like configured
 -name <ID>  .  .  .  .  .  delete name of entry
 -move <IDa> > <IDb>  .  .  move entry a to position (of) b
 -copy  <IDa> > <IDb> .  .  copy entry a to position (of) b
 <  .  .  .  .  .  .  .  .  undo last command
 >  .  .  .  .  .  .  .  .  redo - revert previously made undo

  
  commands for managing lists:
                
 -add-list <lname> .  .  .  create a new list
 -del-list <lID>   .  .  .  delete list of <lname> or <lpos> (has to be empty)
 -name-list <lID>:<lname>   rename list, conflicts not allowed
 -list-list  .  .  .  .  .  <lname> and <lpos> of available lists (short -l-l)
EOH
    }
}
