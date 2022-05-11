use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Help;

my %text = ( overview => \&overview,
             basics   => \&basics,
             commands => \&commands,
             install  => \&install,
             settings => \&settings,
             version  => \&version,
                'add' => \&add,
             'delete' => \&delete,
           'undelete' => \&undelete,
             'remove' => \&remove,
               'move' => \&move,
               'copy' => \&copy,
               'name' => \&name,
                'dir' => \&dir,
              'redir' => \&redir,
             'script' => \&script,
               'list' => \&list,
               'sort' => \&sort,
         'list-lists' => \&llists,
       'list-special' => \&lspecial,
           'add-list' => \&ladd,
        'delete-list' => \&ldelete,
          'name-list' => \&lname,
      'describe-list' => \&ldescription,
               'help' => \&help,
);

sub text {
    my ($config, $ID) = @_;
    $ID = substr $ID, 2 if length($ID) > 2 and substr($ID, 0,2) eq '--';
    (defined $ID and defined $text{$ID}) ? $text{$ID}( $config ) : overview( $config );
}

sub overview {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'help'};
    my $opt = $config->{'syntax'}{'option_shortcut'}{'help'};
    <<EOT;

  Introduction to gt
 --------------------

  Command line tool gt (short for goto) changes the working dir like cd,
  to a user managed set of locations. This frees from memorizing and
  writing long dir path's. But it's also a lightweight tool for tracking
  activities and supporting work in the shell.

  It has two modes of operation: shell and REPL. The first is the normal
  usage via parameters as described by documentation. The second mode
  is called just with 'gt' and accepts the same commands and replies
  with same outputs as the first mode. The only difference: REPL mode
  displays after each batch of commands the content of the current list
  until the user calls a directory or just presses <Enter>. In that case
  it returns to the directory it was called from. In both modes several
  commands can be fired at once.

  To learn more about how to switch the working dir with gt type:

    gt --help=basics    or    gt -$sc$opt->{basics}

  And to see all the commands to manage the stored locations type:

    gt --help=commands    or    gt -$sc$opt->{commands}

  gt can not work out of the box, since no program can change the
  current working directory of the shell by itself. Please read also

    gt --help=install    or    gt -$sc$opt->{install}

  There are many ways to configure gt to your liking:

    gt --help=settings    or    gt -$sc$opt->{settings}
EOT
}
sub basics {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'help'};
    my $opt = $config->{'syntax'}{'option_shortcut'}{'help'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  Basic use of gt
 -----------------

  The prime use of gt is changing the working directory of a shell to a
  directory path (<dir>), that is already stored in a file as an entry.
  Theses entries are organized in named lists (<list>) and may have
  names (<name>) themself. Call gt -$sc$opt->{commands} to learn how to
  administer lists and change the properties of an entry.

  Switch directory by calling gt and identify (with <entryID>) an entry:

    gt [$sig->{entry_name}]<name>           calling entry by name
    gt [$sig->{entry_position}]<pos>            calling entry by position of current list
    gt <list>$sig->{entry_position}<pos>        entry at position of any list

  A negative position is counting from the lists last position (-1 = last).
  If <list> is omitted, than gt assumes the current list. List and entry
  names contain only word character (A-Za-z0-9_) and start with a letter.

  There are a number of special <dir> entry names (starting with $sig->{special_entry}) and
  names of special lists (starting with $sig->{special_list}) that can be used in <entryID>
  like regular named entries or regular lists. These are listed below.

  To any <entryID> can be attached another directory path, that will be
  understood as subdirectory of the entry <dir>:

    gt $sig->{special_entry}last/..            go to parent directory of <dir> gone to last time

  The only special case are two short aliases of special entries, that can
  only be used to switch directory (no subdir allowed):

    gt _                   go to destination of last gt call (alias to $sig->{special_entry}last)
    gt -                   as cd -, second last destination (alias to $sig->{special_entry}previous)


 SPECIAL ENTRIES:

  $sig->{special_entry}last                   destination of last gt call (with subdir)
  $sig->{special_entry}prev[ious]             destination of second last gt call (with subdir)
  $sig->{special_entry}add|[un]del[ete]       every command has special entry with same name,
  $sig->{special_entry}\[re]move|copy          .. which is an alias to the entry touched by
  $sig->{special_entry}dir|name|script        .. the last usage of the command

 SPECIAL LISTS:

  $sig->{special_list}all                    entries from all lists, even $sig->{special_list}bin
  $sig->{special_list}new                    newly created entries (default is 2 weeks old)
  $sig->{special_list}bin                    deleted entries (scrapped after configured period)
  $sig->{special_list}named                  all entries with names
  $sig->{special_list}stale                  all entries with defunct (not existing) <dir>
EOT
}
sub install{
    my $config = shift;
  <<EOT,

  How to install and maintain gt
 --------------------------------

  App::Goto::Dir is a perl module, that requires perl 5.18 and and the YAML module.
  It installs the script goto.pl which is not fully usable out of the box,
  since it can not change the current working directory (cwd) of a shell.
  In order to achieve that, you have to add to the shellrc the line:

  function gt() { perl ~/../goto.pl \\\$@ cd \$\\(cat ~/../last_choice) }

  Replace gt with the name you want to call the app with.
  ~/.. is of course the placeholder for the directory App::Goto::Dir is installed into.
  There should be three files that are very important:

  last_choice      This file is the interface between the script and the shell.
                   Its name can be configured (change shellrc line accordingly).

  places.yml       This file contains all the user data (directories and lists).
                   There is a backup with places.bak.yml (both names configurable).

  goto_dir_config.yml  Contains configuration (settings), it's name is fixed.
                       Defaults are in goto_dir_config_default.yml.
                       If one of these two files is missing, it will be created
                       at the next program start containing the defaults.
EOT
}
sub commands {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'};
    my $opt = $config->{'syntax'}{'option_shortcut'};
    my $sopt = join '|', sort values %{$opt->{'sort'}};
    my $hopt = join '|', sort values %{$opt->{'help'}};
    my $space = ' 'x (15 - length $hopt);
    <<EOT;

  all gt commands in long and short form
 ----------------------------------------

  display commands:

  -$sc->{help} --help[=$hopt| <command>]     topic or command specific help texts
  -$sc->{sort} --sort=$sopt$space    set sorting criterion of list display
  -$sc->{list}  --list [<listname>]            change current list and display it
  -$sc->{'list-special'} --list-special                display all special entries
  -$sc->{'list-lists'} --list-lists                  display available list names

  commands to manage lists:

  -$sc->{'list-add'} --list-add <name> ? <Desc.>   create a new list
  -$sc->{'list-delete'} --list-del[ete] <name>        delete list with <listname> (has to be empty)
  -$sc->{'list-name'} --list-name <name>:<newname>  rename list, conflicts not allowed
  -$sc->{'list-description'} --list-description <name>?<D> change list description

  commands to manage list entries:

  -$sc->{add} --add <dir>[:<name>] [> <ID>]   add directory <dir> under <name> to a list
  -$sc->{delete} --del[ete] [<ID>]               delete dir entries from all regular lists
  -$sc->{undelete} --undel[ete] [<ID>]             undelete dir entries from bin
  -$sc->{remove} --rem[ove] [<ID>]               remove dir entries from a chosen lists
  -$sc->{move} --move [<IDa>] > <IDb>          move dir entry <IDa> to (position of) <IDb>
  -$sc->{copy} --copy [<IDa>] > <IDb>          copy entry <IDa> to (position of) <IDb>

  commands to modify entries:

  -$sc->{dir} --dir [<ID>] <dir>              change directory of one entry
  -$sc->{redir} --redir <old_dir> >> <newdir>   change root directory of more entries
  -$sc->{name} --name [<ID>] [:<name>]         (re-, un-) name entry
  -$sc->{script} --script [<ID>] '<code>'        edit project landing script
EOT
}

sub settings{ <<EOT,

   How to configure Goto Dir
  ---------------------------

  Just edit the YAML file goto_dir_config.yml.
  Default settings can be recovered from goto_dir_config_default.yml.

  file:                               file names
    data:                               current state of dir entry store
    backup: places.bak.yml              state after seconad last usage
    return: last_choice                 directory gone to last time
                                          (communication channel with shell)
  list:                               properties of entry lists
    deprecate_new: 1209600              seconds an entry stays in special list new
    deprecate_bin: 1209600              seconds a deleted entry will be preserved in list bin
    start_with: (current|default)       name of displayed list on app start
    name_default: use                   name of default list
    special_name:                     setting personal names to special lists
      all:                              contains every entry (deleted too)
      bin:                              contains only deleted, not yet scrapped
      idle:                             dormant projects
      new:                              only newly created entries
      named:                            entries with a shortcut name
    special_description:              description texts of special lists
    sorted_by: (current|default)      sorting criterion of list on app start
    sort_default: position            default sorting criterion
  entry:                              properties of entry lists
    dir_move                            allow --redir to rename dir in file system
    dir_exists                          accept only existing dir
    max_name_length: 5                  maximal entry name length
    position_default: -1                when list position is omitted take this
    prefer_in_name_conflict: (new|old)  How resolve name conflict (one entry looses it) ?
    prefer_in_dir_conflict: (new|old)   Create a new entry with already use dir or del old ?
  syntax:                             syntax of command line interface
    sigil:                              special character that start a kind of input
      short_command: '-'                  first char of short form command
      help: '?'                           separator for help text (see --list-add)
      file: '<'                           separator for file name
      entry_name: ':'                     separator for entry name
      entry_position: '^'                 separator for list position
      target_entry: '}'                   separator between source and target
      special_entry: '+'                  first char of special entry name like '+last'
      special_list: '@'                   first char of special list name like '\@all'
    special_entry:                      short alias of special entries
      last: '_'                           the dir gone to last time
      previous: '-'                       the dir gone to before
      new: '*'                            the dir of last created dir
    command_shortcut:                   short command names (default is first char)
    option_shortcut:                    shortcuts for command options (start with '=')
      help:                               option shortcuts for command 'help'
EOT
}
sub version {
    my $config = shift;
    my $us = '-'x length $App::Goto::Dir::VERSION;
    <<EOT;

   App::Goto::Dir $App::Goto::Dir::VERSION
  -----------------$us

  Command line tool gt for long distance directory jumps

  Herbert Breunung 2021

  For more help use gt --help help or gt -$config->{syntax}{command_shortcut}{help} $config->{syntax}{command_shortcut}{help}
EOT
}

sub add {
    my $config = shift;
    my $cmd = 'add';
    my $lname = $config->{'list'}{'special_name'};
    my $d = $config->{'list'}{'deprecate_new'} / 86400;
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --add      create a new entry
 ----------------------------------

    Creates a new entry to store the directory <dir> in. The new entry may get a <name>
    and may be inserted into a list named <list> at a position <pos>. In any case will
    the entry appear in special lists, including $sig->{special_list}$lname->{all} (all entries, even the deleted ones)
    and $sig->{special_list}$lname->{new} (all newly created entries). It will remain in $sig->{special_list}$lname->{new} for $d days
    (to be configured via key entry.deprecate_new in goto_dir_config.yml).
    If <dir> is already stored in any list, entry.prefer_in_dir_conflict decides,
    if new or old entry is kept.
    If <dir> is omitted, it defaults to the directory gt is called from.
    If <name> is already used by any entry, entry.prefer_in_name_conflict decides,
    if new or old entry will keep it. <name> defaults to the empty (no) name.
    A missing target <entryID> defaults to the default position ($config->{'entry'}{position_default}) in the current list.
    Name the special list $sig->{special_list}$lname->{all} as target, so the new entry enters no regular list.

 USAGE:

  --add  [<dir>] [$sig->{entry_name}<name>] [<target>]    long command name
   -$sc\[<dir>] [$sig->{entry_name}<name>] [<target>]        short form alias


 EXAMPLES:

  --add /project/dir         add the directory into current list on default position with no name
   -$sc/path $sig->{entry_name}p                add path into same place but under the name 'p'
  --add /path $sig->{entry_name}p [$sig->{entry_position}]3        add named path to current list on third position
  --add /path good$sig->{entry_position}4         add unnamed path to list named 'good' on fourth position
  --add /path good$sig->{entry_name}s         add unnamed path to list 'good' on position of entry named 's'
  --add /path $sig->{special_list}$lname->{all}           add new entry to no regular list
  --add good$sig->{entry_position}2/sub/dir :gg   combine <dir> of entry nr.2 in list 'good' with subdirectory '/sub/dir'

    Space (' ') is after --$cmd required, but after '-$sc' optional. It has to separate
    argument tokens like <dir> and <name>. Inside of them no unquoted space is allowed.
    <dir> has to start with '/', '\\' or '~'. If <dir> contains space (' '), '$sig->{target_entry}' or '$sig->{entry_name}',
    it has to be set in single quotes ('/a path').
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub delete {
    my $config = shift;
    my $cmd = 'delete';
    my $lname = $config->{'list'}{'special_name'};
    my $d = $config->{'list'}{'deprecate_bin'} / 86400;
    my $sig = $config->{'syntax'}{'sigil'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
     <<EOT;

  gt --delete      delete entry from store
 ------------------------------------------

    Deletes a specified <dir> entry from all lists except the special lists liks $sig->{special_list}$lname->{all}.
    The entry will also be moved to the special list $sig->{special_list}$lname->{bin} and scrapped fully after $d days.
    This duration may be configured via the config entry: entry.deprecate_bin in goto_dir_config.yml.
    Use --undelete to move entries back into regular lists.

 USAGE:

  --delete  [<entry>]      long command name
  --del  [<entry>]         shorter alias
   -$sc\[<entry>]             short form alias


 EXAMPLES:

  --delete                   removing entry on default position ($config->{'entry'}{'position_default'}) of current list from all lists
  --del [$sig->{entry_position}]2                 delete second entry of current list
  --del idle$sig->{entry_position}-2              delete second last entry of list 'idle'
  --del good$sig->{entry_position}1..3            delete first, second and third entry of list named 'good'
  --del good$sig->{entry_position}..              delete all entries list 'good'
  --del $sig->{special_entry}new                 deleting a previosly created entry
   -$sc\[$sig->{entry_name}]fm$sig->{entry_name}pm                delete entry named 'fm' and entry named 'pm'

    Space (' ') is after --$cmd required, but after '-$sc' optional and inside <entry> not allowed.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position can be negative, counting from the last position.
EOT
}
sub undelete {
    my $config = shift;
    my $cmd = 'undelete';
    my $lname = $config->{'list'}{'special_name'};
    my $d = $config->{'list'}{'deprecate_bin'} / 86400;
    my $sig = $config->{'syntax'}{'sigil'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
     <<EOT;

  gt --undelete      restore deleted entry
 ------------------------------------------

    Removes a specified <dir> entry from the special list $sig->{special_list}$lname->{bin} and also stops the
    countdown to scrap the entry ($d days) after deletion.
    The entry may also be moved into a regular list like with --move.

 USAGE:

  --undelete  [<entry>] [<target>]     long command name
  --undel  [<entry>] [<target>]        shorter alias
   -$sc\[<entry>] [<target>]              short form alias


 EXAMPLES:

  --undelete                 undelete entry on default position in $sig->{special_list}$lname->{bin}
  --undel [$sig->{entry_position}]2               undelete second entry in $sig->{special_list}$lname->{bin}
  --undel 2  idle$sig->{entry_position}-1         undelete second entry and insert it as last entry of list 'idle'
  --undel [$sig->{entry_position}]1..3            undelete first, second and third entry of $sig->{special_list}$lname->{bin}
  --undel [$sig->{entry_name}]good            undelete entry named 'good'
   -$sc\[$sig->{entry_name}]fm sound$sig->{entry_name}pm          undelete 'fm' and move to postion of 'pm' in list 'sound'

    Space (' ') is after --$cmd required, but after '-$sc' optional. It has to separate
    argument tokens like <entry> and <target>. Inside of them no unquoted space is allowed.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position can be negative, counting from the last position.
EOT
}
sub remove {
    my $config = shift;
    my $cmd = 'remove';
    my $lname = $config->{'list'}{'special_name'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
    my $sig = $config->{'syntax'}{'sigil'};
    my $arg = "good$sig->{entry_name}ll";
    <<EOT;

  gt --remove      remove entry from list
 -----------------------------------------

    Removes one or more <dir> entries from a regular list.
    Special lists like $sig->{special_list}$lname->{new}, $sig->{special_list}$lname->{all}, $sig->{special_list}$lname->{stale} and $sig->{special_list}$lname->{bin} will not respond.

 USAGE:

  --remove  [<entry>]    long command name
  --rm  [<entry>]        shorter alias
   -$sc\[<entry>]           short form alias


 EXAMPLES:

  --remove               remove entry on default position ($config->{'entry'}{'position_default'}) of current list
  --rm [$sig->{entry_position}]-1             remove entry from last position of current list
  --rm good$sig->{entry_position}4            remove entry from fourth position of list named 'good'
  --rm good$sig->{entry_position}4..          remove entries from second to last position of list 'good'
  --rm good$sig->{entry_position}..           remove all entries from list named 'good'
  --rm $sig->{entry_name}ll $sig->{entry_name}gg           remove entries named 'll' and 'gg' from current list
   -$sc$arg$sig->{entry_name}gg          remove entries 'll' and 'gg' from list named 'good'

    Space (' ') is after --$cmd required, but after '-$sc' optional and inside <entry> not allowed.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub move {
    my $config = shift;
    my $cmd = 'move';
    my $lname = $config->{'list'}{'special_name'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
    my $sig = $config->{'syntax'}{'sigil'};
    my $arg = "2 -1";
    <<EOT;

  gt --move      move entry from one to another list
 ----------------------------------------------------

    Removes a specified entry from a list in any case and inserts it into another list.
    If source and target list are the same, it only changes it's position in list.
    Entries can not be moved into and out of the special lists like $sig->{special_list}$lname->{new} and $sig->{special_list}$lname->{all}.
    Only exception: they can be moved out of $sig->{special_list}$lname->{bin} to undelete entries.
    Use the command --delete to move an entry out of all regular lists into $sig->{special_list}$lname->{bin}.

 USAGE:

  --move  [<source>] <target>    long command name
  --mv  [<source>] <target>      shorter alias
   -$sc\[<source>] <target>         short form alias


 EXAMPLES:

  --move  idle$sig->{entry_position}3             move from default position ($config->{'entry'}{'position_default'}) of current list to third pos. of list 'idle'
   -$sc$arg                    move entry from second to last position in current list
  --mv good$sig->{entry_position}4 better$sig->{entry_position}2       move entry from fourth position of list 'good' to second pos. of 'better'
  --mv good$sig->{entry_position}..5 better$sig->{entry_position}2     move entries 1 to 5 of list 'good' to second pos. of 'better'
  --mv good$sig->{entry_position}.. better$sig->{entry_position}2      move all entries in list 'good' to second pos. of 'better'
  --mv rr good               move entry in current list named 'rr' to default position of list 'good'
  --mv meak$sig->{entry_name}rr great$sig->{entry_name}d       move entry 'rr' in list 'meak' to position of entry 'd' in list 'great'
  --move $sig->{special_entry}copy great         move the most recently copied entry into list 'great'

    Space (' ') is after --$cmd required, but after '-$sc' optional. It has to separate
    argument tokens like <source> and <target>. Inside of them no unquoted space is allowed.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub copy {
    my $config = shift;
    my $cmd = 'copy';
    my $lname = $config->{'list'}{'special_name'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{$cmd};
    my $sig = $config->{'syntax'}{'sigil'};
    my $arg = "2 -1";
    <<EOT;

  gt --copy      copy entry from one to another list
 ----------------------------------------------------

    Insert an entries into a regular list, but not a special list like $sig->{special_list}$lname->{new}, $sig->{special_list}$lname->{all} and $sig->{special_list}$lname->{bin}.
    If entry is already list element, the config key entry.prefer_in_dir_conflict
    in goto_dir_config.yml decides if new or old entry is kept.

 USAGE:

  --copy  [<sourceID>] <targetID>    long command name
  --cp  [<sourceID>] <targetID>      shorter alias
   -$sc\[<sourceID>] <targetID>         short form alias


 EXAMPLES:

  --copy idle$sig->{entry_position}3              copy from default position ($config->{'entry'}{'position_default'}) of current list to third position of 'idle'
   -$sc$arg                    copy from second to last position in current list (produces dir_conflict!)
  --cp all$sig->{entry_position}4 better$sig->{entry_position}2        copy entry from fourth position of list 'all' to second pos. of 'better'
  --cp all$sig->{entry_position}..4 better$sig->{entry_position}2      copy first four entries of list 'all' to second pos. of 'better'
  --cp $sig->{special_list}stale$sig->{entry_position}.. weird       copy all entries of special list '$sig->{special_list}stale' to default position of 'weird'
  --cp $sig->{special_entry}move idle$sig->{entry_position}3          copy recently moved entry to third pos. of list 'idle'
  --cp rr good               copy entry named 'rr' (of any list) to default position of list 'good'
  --cp $sig->{entry_name}rr great$sig->{entry_name}d           copy entry 'rr' to position of entry 'd' in list 'great'

    Space (' ') is after --$cmd required, but after '-$sc' optional. It has to separate
    argument tokens like <source> and <target>. Inside of them no unquoted space is allowed.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub name {
    my $config = shift;
    my $lname = $config->{'list'}{'special_name'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{'name'};
    my $sig = $config->{'syntax'}{'sigil'};
    my $arg = "mi$sig->{entry_name}fa";
    <<EOT;

  gt --name      change entry name
 ----------------------------------

    Change the unique name (throughout all lists) of an entry. If <name> is omitted,
    it defaults to an empty string, which results in deleting the name.
    If <name> is already used by another entry, the config key:
    entry.prefer_in_name_conflict in goto_dir_config.yml decides,
    if the new (this) or old (other) entry will keep it.
    All entries with a name appear in the special list: $sig->{special_list}$lname->{named}.

 USAGE:

  --name  [<entryID>] [$sig->{entry_name}<name>]    long command name
   -$sc\[<entryID>] [$sig->{entry_name}<name>]         short alias


 EXAMPLES:

  --name                     delete name of entry on default position ($config->{'entry'}{'position_default'}) of current list
  --name $sig->{entry_name}do                 set name of default entry to 'do'
  --name idle$sig->{entry_position}3$sig->{entry_name}re           give entry on third position of list 'idle' the name 're'
   -$sc$arg                   rename entry 'mi' to 'fa'
  --name sol                 delete name of entry 'sol'

    Space (' ') is after '$sig->{entry_position}' and '$sig->{entry_name}' not allowed, but after --name required.
    Space before '$sig->{entry_position}' or '$sig->{entry_name}' and after -$sc is optional.
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub dir {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'dir'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --dir      change dir path of entry
 ----------------------------------------

    Change directory <dir> of one spcified entry. gt switches into <dir>, when entry is selected.
    If <dir> is already stored in any other entry, the config key entry.prefer_in_dir_conflict
    in goto_dir_config.yml decides, if this ('new') or  the other ('old') entry is kept.

 USAGE:

  --dir  [<entryID>] <dir>    long command name
   -$sc\[<entryID>] <dir>        short alias


 EXAMPLES:

  --dir ~/perl/project            set path of default entry ($config->{'entry'}{'position_default'}) in current list to '~/perl/project'
   -$sc/usr/temp                    change <dir> of default entry in current list to '/usr/temp'
  --dir $sig->{entry_name}sol /usr/bin             set path of entry named 'sol' to /usr/bin
  --dir idle$sig->{entry_position}3 /bin/da            set path of third entry in list 'idle' to /bin/da

    Space (' ') is after '$sig->{entry_position}' and '$sig->{entry_name}' not allowed, but after --dir required.
    Space before '$sig->{entry_position}' or '$sig->{entry_name}' and after -$sc is optional.
    <dir> has to start with '/', '\\' or '~'. If <dir> contains space (' '), '$sig->{target_entry}' or '$sig->{entry_name}',
    it has to be set in single quotes ('/a path').
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub redir {
    my $config = shift;
    my $lname = $config->{'list'}{'special_name'};
    my $sc = $config->{'syntax'}{'command_shortcut'}{'redir'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --redir      change root dir of entries
 --------------------------------------------

    Change directory <dir> of several entries by replacing the first part of the
    stored path (<old_dir>) with a new path (<new_dir>). This comes handy when a
    directory in the file system was renamed (like with mv). --redir is just a way
    to announce this change to gt so that all entries can change <dir> accordingly.
    Entries with <dir> that no longer exists appear in special list $sig->{special_list}$lname->{stale}.
    if --redir changes <dir> that do exist, gt will also rename the <old_dir> to
    <new_dir> in the file system, unless config key: entry.move_dir is zero/empty.

 USAGE:

  --redir  <old_dir> [$sig->{file}$sig->{file}] <new_dir>    long command name
   -$sc\<old_dir>$sig->{file}$sig->{file}<new_dir>            short alias


 EXAMPLES:

  --redir /code/purl $sig->{file}$sig->{file} /code/perl  replace '/code/purl' with '/code/perl' in every entry <dir>

    Space (' ') around '$sig->{file}$sig->{file}'  and after -$sc is optional. <dir> has to start with '/', '\\' or '~'.
    If <dir> contains space (' '), '$sig->{target_entry}' or '$sig->{entry_name}', it has to be set in single quotes ('/a path').
EOT
}
sub script {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'script'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --script      change landing script
 ----------------------------------------

    Find an entry and change its <script> property - a snippet of perl code, that
    is run, after switching into the entries <dir>. It's output will be displayed.

 USAGE:

  --script  [<entryID>] ('<code>'| $sig->{file} <file>)    long command name
   -$sc\[<entryID>] ('<code>'|$sig->{file}<file>)             short alias


 EXAMPLES:

  --script 'say "dance"'       set code of default entry ($config->{'entry'}{'position_default'}) in current list to 'say "dance"'
  --script $sig->{entry_name}sol 'say "gg"'     set landing script code of entry bamed 'sol' to 'say "gg"'
  --script $sig->{entry_name}sol </dir/code.pl  set code of entry to content of file '/dir/code.pl'
  --script idle$sig->{entry_position}3 'say f2()'   set code of third entry in list 'idle' to 'say f2()'
   -$sc\'say 99'                  change <script> of default entry in current list to 'say 99'

    Space (' ') is after '$sig->{entry_position}' and '$sig->{entry_name}' not allowed, but after --script required.
    Space before '$sig->{entry_position}' or '$sig->{entry_name}' and after -$sc is optional.
    If <file> contains space character, it has to be set in single quotes ('/a path/file.pl').
    Entry names are globally unique (over all lists). Like list names, they contain only
    word character (A-Z,a-z,0-9,_) and have to start with a letter.
    List position may be negative, counting from the last position.
EOT
}
sub list {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'list'};
    <<EOT;

  gt --list      display list of entries
 ----------------------------------------

    Set the name of the current list, that will be displayed immediately.
    When running the gt REPL shell (open via gt without any arguments), the current list
    will be displayed after each command. There you need --list only to switch the shown list.
    When calling gt with arguments you need --list to get any (or several) lists displayed.
    All commands regarding lists start with --list-.. but are separate commands.

 USAGE:

  --list  [<listname>]    long command name
   -$sc\[<listname>]         short alias


 EXAMPLES:

    gt --list a b         display list named 'a' and 'b' and set current list to 'b'

    List names contain only word character (A-Z,a-z,0-9,_) and start with a letter.
EOT
}
sub sort {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'sort'};
    my $opt = $config->{'syntax'}{'option_shortcut'}{'sort'};
    <<EOT;

  gt --sort      set list sorting criterion
 -------------------------------------------

    Set the sorting criterion applied at the next use of --list (displays an entry list).
    Unless the criterion is position, name or dir, --list inserts a fourth column
    with the values that caused the sorting order (in a human readable format).
    After the list is displayed, the criterion switches back to default,
    unless the config key: list.sorted_by ($config->{list}{sorted_by}) is set to 'current'.
    The default criterion ($config->{list}{sort_default}) is set by the config key: list.sort_default.
    Calling --sort without an option also resets the criterion to default.
    Putting a '!' in front of the criterion means: reversed order.
    Every option has a short alias as shown in the first, leftmost column.

 USAGE:

   -$sc   --sort                  set to default criterion ($config->{list}{sort_default})
   -$sc$opt->{position}  --sort=position         obey user defined positional ordering of list
   -$sc$opt->{dir}  --sort=dir              alphanumeric ordering of directories
   -$sc$opt->{name}  --sort=name             alphanumeric ordering of entry names, unnamed last
   -$sc$opt->{script}  --sort=script           alphanumeric ordering of landing scripts
   -$sc$opt->{visits}  --sort=visits           number of visits, most visited first
   -$sc$opt->{last_visit}  --sort=last_visit       time of last visit, the very last first
   -$sc$opt->{created}  --sort=created          time of creation, oldest first
   -$sc!$opt->{created} --sort=!created         time of creation, newest first
EOT

}
sub lspecial {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'list-special'};
    <<EOT;

  gt --list-special      all list names
 ---------------------------------------

    Display overview with all special entries and their directory.

 USAGE:

  --list-special    long command name
   -$sc             short alias
EOT
}
sub llists {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'list-lists'};
    <<EOT;

  gt --list-lists      all list names
 -------------------------------------

    Display overview with all list names. The special ones are marked with '$config->{syntax}{sigil}{special_list}' and their function.

 USAGE:

  --list-lists    long command name
   -$sc           short alias
EOT
}
sub ladd {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'add-list'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --add-list      create a list
 ----------------------------------

    Create a new empty regular list for path entries. It's mandatory <name> can't be taken by another list.
    It also needs a description text (in single quotes).

 USAGE:

  --add-list  <name> [$sig->{help}] <description>    long command name
   -$sc<name>[$sig->{help}]<description>             short alias


 EXAMPLES:

  --add-list  bear 'only the best entries'    creates a new list named 'bear'

    Space (' ') after --add-list is required, but after -$sc optional.
    List names have to be unique, contain only word character (A-Za-z0-9_) and start with a letter.
EOT
}
sub ldelete {
    my $config = shift;
    my $cmd = 'delete-list';
    my $sc = $config->{'syntax'}{'command_shortcut'}{'delete-list'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

   gt --list-delete      remove an empty list
  --------------------------------------------

    Deletes an empty, not special (user created) list. There is no undelete, but --add-list.
    To emty a list use --move <name>$sig->{entry_position}.. <targetID> or --remove <name>$sig->{entry_position}.. (or --delete).

 USAGE:

  --delete-list  <name>    long command name
  --del-list  <name>       shorter alias
   -$sc<name>              short alias

    Space (' ') after $cmd and --del-list is required, but after -$sc optional.
    List names have to be unique, contain only word character (A-Za-z0-9_) and start with a letter.
EOT
}
sub lname {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'name-list'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --name-list      rename a list
 -----------------------------------

    Change name of any list, even the special ones (start with $sig->{special_list}). Does not work when <newname> is taken.

 USAGE:

  --name-list  <oldname> $sig->{entry_name}<newname>    long command name
   -$sc<oldname>$sig->{entry_name}<newname>             short alias


    Space (' ') after --name-list is required, but after -$sc and around '$sig->{entry_name}' optional.
    List names have to be unique, contain only word character (A-Za-z0-9_) and start with a letter.
EOT
}
sub ldescription {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'describe-list'};
    my $sig = $config->{'syntax'}{'sigil'};
    <<EOT;

  gt --describe-list      change description of list
 ----------------------------------------------------

    Change description text of a list, even the special ones (start with $sig->{special_list}). Does not work when <newname> is taken.

 USAGE:

  --describe-list  <name> '<description>'    long command name
   -$sc<name>'<description>'                 short alias


    Space (' ') after --describe-list is required, but after -$sc and around '$sig->{help}' optional.
    List names have to be unique, contain only word character (A-Za-z0-9_) and start with a letter.
EOT
}
sub help {
    my $config = shift;
    my $sc = $config->{'syntax'}{'command_shortcut'}{'help'};
    my $opt = $config->{'syntax'}{'option_shortcut'}{'help'};
    <<EOT;

  gt --help      display documentation
 --------------------------------------

  --help            -$sc         overview

  --help=basics     -$sc$opt->{basics}        how to change directory, special lists and entries
  --help=commands   -$sc$opt->{commands}        list of all commands (cheat sheet)
  --help=install    -$sc$opt->{install}        how to install and maintain the program
  --help=settings   -$sc$opt->{settings}        how to configure the program

  --help <command>  -$sc<cmd>    detailed explanation of one <command> (e.g. --add)
                               command shortcut (<cmd>) may be used instead (e.g. -$config->{'syntax'}{'command_shortcut'}{'add'})
                               space before <command> is needed, but not before <cmd>.
EOT
}

1;
