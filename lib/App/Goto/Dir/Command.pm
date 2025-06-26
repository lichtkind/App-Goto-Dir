
# exec user CLI commands

package App::Goto::Dir::Command;
use v5.20;
use warnings;
no warnings  qw/experimental::smartmatch/;
use feature qw/switch/;
use File::Spec;
use App::Goto::Dir::Data;
use App::Goto::Dir::Help;

my %special_entry = ( last => 'entry last visited',
                      prev => 'entry second last visited',
                      add  => 'last entry created',
                      del  => 'last entry deleted',
                      name => 'last entry named',
                      move => 'last entry copied, moved or removed',);


my         ($config, $data, $cwd);
sub init { ($config, $data, $cwd) = @_ }
sub run {
   my ($cmd, @arg) = @_;
   if    ($cmd eq 'help')            { App::Goto::Dir::Help::text(              $config,        @arg)   }
   elsif ($cmd eq 'version')         { App::Goto::Dir::Help::text(              $config,        $cmd   )}
   elsif ($cmd eq 'sort')            { App::Goto::Dir::Format::set_sort(        $config, $data, $arg[0])}
   elsif ($cmd eq 'list')            { App::Goto::Dir::Format::list_entries(    $config, $data, @arg )  }
   elsif ($cmd eq 'list-special')    { App::Goto::Dir::Format::special_entries( $config, $data       )  }
   elsif ($cmd eq 'list-lists')      { App::Goto::Dir::Format::lists(           $config, $data       )  }
   elsif ($cmd eq 'add-list')        {                         add_list(                        @arg )  }
   elsif ($cmd eq 'delete-list')     {                         delete_list(                     @arg )  }
   elsif ($cmd eq 'name-list')       {                         name_list(                       @arg )  }
   elsif ($cmd eq 'describe-list')   {                         describe_list(                   @arg )  }
   elsif ($cmd eq 'add')             {                         add_entry(                       @arg )  }
   elsif ($cmd eq 'delete')          {                         delete_entry(                    @arg )  }
   elsif ($cmd eq 'undelete')        {                         undelete_entry(                  @arg )  }
   elsif ($cmd eq 'remove')          {                         remove_entry(                    @arg )  }
   elsif ($cmd eq 'move')            {                         move_entry(                      @arg )  }
   elsif ($cmd eq 'copy')            {                         copy_entry(                      @arg )  }
   elsif ($cmd eq 'dir')             {                         dir_entry(                       @arg )  }
   elsif ($cmd eq 'name')            {                         name_entry(                      @arg )  }
   elsif ($cmd eq 'script')          {                         script_entry(                    @arg )  }
   elsif ($cmd eq 'goto')            {                         goto_entry(                      @arg )  }
   else                              {                         goto_entry(                      @arg )  }
}
#### LIST COMMANDS #####################################################
sub add_list {
    my ($list_name, $decription) = @_;
    return ' ! need an unused list name as first argument' unless defined $list_name;
    return ' ! need the lists description as second  argument' unless defined $decription and $decription;
    return " ! can not create special lists" if substr ($list_name, 0, 1 ) =~ /\W/;
    return " ! '$list_name' is not a regular list name (only [A-Za-z0-9_] start with letter)" unless App::Goto::Dir::Parse::is_name($list_name);
    return " ! list '$list_name' does already exist" if $data->list_exists( $list_name );
    $data->new_list( $list_name, $decription, $config->{'entry'} );
    " - created list '$list_name' : '$decription'";
}
sub delete_list {
    my ($list_name) = @_;
    return ' ! need a name of an existing, regular list as first argument' unless defined $list_name;
    return " ! can not delete special lists" unless App::Goto::Dir::Parse::is_name($list_name);
    return " ! list '$list_name' does not exists" unless $data->list_exists( $list_name );
    return " ! can not delete none empty list $list_name" if $data->get_list( $list_name )->elems();
    my $list = $data->remove_list( $list_name );
    " - deleted list '$list_name' : '".$list->get_description."'";
}
sub name_list {
    my ($old_name, $new_name) = @_;
    return ' ! need a name of an existing list as first argument' unless defined $old_name;
    return ' ! need an unused list name as second argument' unless defined $new_name;
    my $sig = $config->{'syntax'}{'sigil'}{'special_list'};
    if (substr $old_name, 0, 1 eq $sig){ $new_name = $sig.$new_name      if App::Goto::Dir::Parse::is_name($new_name) }
    else                               { $new_name = substr 1, $new_name if substr($new_name, 0, 1 eq $sig)           }

    my $list = $data->get_list( $old_name );
    return " ! there is no list named '$old_name'" unless ref $list;
    return " ! list name '$new_name' is already in use" if ref $data->get_list( $new_name );
    if (substr ($old_name, 0, 1 ) eq $sig and substr ($new_name, 0, 1 ) eq $sig){
        my $oname = substr $old_name, 0, 1;
        my $nname = substr $new_name, 0, 1;
        return " ! '$nname' is not a list name (only [A-Za-z0-9_], start with letter)" unless App::Goto::Dir::Parse::is_name($nname);
        for my $key (keys %{$config->{'list'}{'special_name'}}){
            $config->{'list'}{'special_name'}{$key} = $nname if $config->{'list'}{'special_name'}{$key} eq $oname;
        }
    } else {
        return " ! '$new_name' is not a list name (only [A-Za-z0-9_], start with letter)" unless App::Goto::Dir::Parse::is_name($new_name);
    }
    $data->change_list_name( $old_name, $new_name );
    " - renamed list '$old_name' to '$new_name'";
}
sub describe_list {
    my ($list_name, $list_description) = @_;
    return ' ! need a list name as first argument' unless defined $list_name;
    return ' ! need a list description as second argument' unless defined $list_description;
    my $list = $data->get_list( $list_name );
    return " ! there is no list named '$list_name'" unless ref $list;
    $list->set_description( $list_description );
    " - set description of list '$list_name': '$list_description'";
}
#### LIST ADMIN COMMANDS ###############################################
sub add_entry {
    my ($dir, $name, $target) = @_;
    if (ref $dir eq 'ARRAY') {
        return ' ! subdirectory of existing entry is missing' if @$dir < 2;
        return ' ! too many arguments for building a directory to add' if @$dir > 3;
        if (@$dir == 2){ # [name subdir]
            my $entry = $data->get_entry( undef, $dir->[0] );
            return " ! there is no entry named '$dir->[0]'" unless ref $entry;
            $dir = File::Spec->catdir( $entry->full_dir, $dir->[1] );
        } elsif (@$dir == 3) { # [list pos subdir]
            return " ! there is no list named '$dir->[0]'" unless $data->list_exists( $dir->[0] );
            my $entry = $data->get_entry( $dir->[0], $dir->[1] );
            return " ! there is no entry with name or position '$dir->[0]' in list '$dir->[1]'" unless ref $entry;
            $dir = File::Spec->catdir( $entry->full_dir, $dir->[2] );
        } elsif (@$dir == 4) { # [specialname subdir 0  0 ]
            my $entry = $data->get_special_entry_dir( $dir->[0] );
            return " ! there is no special entry named '$dir->[0]'" unless ref $entry;
            $dir = File::Spec->catdir( $entry->full_dir, $dir->[1] );
        } else {}
    }
    my $all_name = $data->get_special_list_names('all');
    $dir  //= $cwd;
    $name //= '';
    $target_ID  //= $config->{'entry'}{'position_default'};
    $target_list_name //= App::Goto::Dir::Parse::is_position( $target_ID ) ? $data->get_current_list_name : $all_name;
    return " ! '$dir' is not an accessible directory" if $config->{'entry'}{'dir_exists'} and not -d $dir;
    return " ! '$name' is not an entry name (only [a-zA-Z0-9_] starting with letter)" if $name and not App::Goto::Dir::Parse::is_name($name);
    return " ! entry name '$name' is too long, max length is $config->{entry}{name_length_max} character" if $name and length($name) > $config->{'entry'}{'name_length_max'};
    my $target_list  = $data->get_list( $target_list_name );
    return " ! target list named '$target_list_name' does not exist, please check --list-lists" unless ref $target_list;
    return " ! the only special list allowed as target is $all_name" if $target_list->is_special and $target_list_name ne $all_name;
    my $pos = $target_list->pos_from_ID( $target_ID, 'target' );
    return " ! position or name '$target_ID' does not exist in list '$target_list_name'" unless $pos;
    my $entry = App::Goto::Dir::Data::Entry->new($dir, $name);
    my ($all, $new, $named, $stale) = $data->get_special_lists(qw/all new named stale/);
    ($target_list, $pos) = ($all, $config->{'entry'}{'position_default'}) unless $target_list eq $all or $target_list->is_special;
    my $insert_error = $all->insert_entry( $entry, $target_list eq $all ? $target_ID : undef ); # sorting out names too
    return " ! $insert_error" unless ref $insert_error; # return error msg: could not inserted because not allowed overwrite entry with same dir
    $new->insert_entry( $entry );
    $named->insert_entry( $entry ) if $entry->name;
    $stale->insert_entry( $entry ) unless -d $entry->full_dir;
    $target_list->insert_entry( $entry, $target_ID ) unless $target_list eq $all;
    $data->set_special_entry( 'add', $entry, $target_list_name);
    " - added dir '$dir' to list '$target_list_name' on position $pos";
}

sub delete_entry {
    my ($entries) = @_; # ID can be [min, max] # range
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name  //= App::Goto::Dir::Parse::is_position( $entry_ID ) ? $data->get_current_list_name : $data->get_special_list_names('all');
    my $list  = $data->get_list( $list_name );
    return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
    if (ref $entry_ID eq 'ARRAY'){
        $entry_ID->[0] //= 1;
        $entry_ID->[1] //= -1;
        my $start_pos = $list->pos_from_ID( $entry_ID->[0] );
        my $end_pos = $list->pos_from_ID( $entry_ID->[1] );
        return " ! '$entry_ID->[0]' is not a valid position in list '$list_name'" unless $start_pos;
        return " ! '$entry_ID->[1]' is not a valid position in list '$list_name'" unless $end_pos;
        $entry_ID = [$start_pos .. $end_pos];
    } else { $entry_ID = [$entry_ID] }
    my $ret = '';
    for my $ID (reverse @$entry_ID){
        my $pos = $list->pos_from_ID( $ID );
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless $pos;
        my ($entry) = $list->get_entry( $pos );
        my $lnames =  '';
        for my $list_name ($entry->member_of_lists) {
            next unless App::Goto::Dir::Parse::is_name( $list_name ); # ignore special lists
            $data->get_list( $list_name )->remove_entry( $entry->get_list_pos( $list_name ) );
            $lnames .= "$list_name, ";
        }
        chop $lnames;
        chop $lnames;
        my $was_del = $entry->overdue();
        unless ($entry->overdue()){
            $entry->delete();
            my ($bin_list) = $data->get_special_lists('bin');
            $bin_list->insert_entry( $entry );
        }
        my $entry_address = App::Goto::Dir::Parse::is_position( $ID ) ? $list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$pos
                                                                      : $config->{'syntax'}{'sigil'}{'entry_name'}.$ID;
        $ret .= $was_del ? " ! '$entry_address' was already deleted\n"
                         : " - deleted entry '$entry_address' ".App::Goto::Dir::Format::text($entry->full_dir(), 30)." from lists: $lnames\n";
        $data->set_special_entry( 'del', $entry, $list_name );
        $data->set_special_entry( 'delete', $entry, $list_name );
    }
    chomp($ret);
    $ret;
}

sub undelete_entry {
    my ($entries) = @_; # ID can be [min, max] # range
    $source_entry_ID  //= $config->{'entry'}{'position_default'};
    $target_entry_ID  //= $config->{'entry'}{'position_default'};
    $target_list_name //= $data->get_current_list_name;
    my $target_list  = $data->get_list( $target_list_name );
    my ($bin, $all) = $data->get_special_lists(qw/bin all/);
    return " ! target list named '$target_list_name' does not exist, please check --list-lists" unless ref $target_list;
    my $target_pos = $target_list->pos_from_ID( $target_entry_ID, 'target' );
    return " ! position or name '$target_entry_ID' does not exist in list '$target_list_name'" unless $target_pos;
    my $target_address = App::Goto::Dir::Parse::is_position($target_entry_ID) ? $target_list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$target_entry_ID
                                                                              : $target_list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$target_entry_ID;
    my $has_target =  App::Goto::Dir::Parse::is_name( $target_list_name );
    if (ref $source_entry_ID eq 'ARRAY'){
        $source_entry_ID->[0] //= 1;
        $source_entry_ID->[1] //= -1;
        my $start_pos = $bin->pos_from_ID( $source_entry_ID->[0] );
        my $end_pos = $bin->pos_from_ID( $source_entry_ID->[1] );
        return " ! '$source_entry_ID->[0]' is not a valid position in list '".$bin->get_name."', check --list ".$bin->get_name unless $start_pos;
        return " ! '$source_entry_ID->[1]' is not a valid position in list '".$bin->get_name."', check --list ".$bin->get_name unless $end_pos;
        $source_entry_ID = [$start_pos .. $end_pos];
    } else {
        return " ! position or name '$source_entry_ID' does not exist in list '".$bin->get_name."', check --list ".$bin->get_name
            unless $bin->pos_from_ID( $source_entry_ID );
        $source_entry_ID = [$source_entry_ID] ;
    }
    my $ret = '';
    for my $ID (reverse @$source_entry_ID){
        my $entry = $bin->remove_entry( $ID );
        $entry->undelete();
        $target_list->insert_entry( $entry, $target_pos ) if $has_target;
        my $src_address = App::Goto::Dir::Parse::is_position( $ID ) ? $bin->get_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$ID
                                                                    : $bin->get_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$ID;
        $ret .= " - undeleted entry '$src_address' ".App::Goto::Dir::Format::text($entry->full_dir(), 30)
                .($has_target ? " and moved to '$target_address'\n" : "\n");
        $data->set_special_entry( $_, $entry ) for qw/undel undelete/;
    }
    chomp($ret);
    $ret;
}

sub remove_entry {
    my ($entries) = @_;  # ID can be [min, max] # range
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name //= $data->get_current_list_name;
    my $list  = $data->get_list( $list_name );
    return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
    return " ! list '$list_name' is not regular, please check --list-lists" if $list->is_special;
    if (ref $entry_ID eq 'ARRAY'){
        $entry_ID->[0] //= 1;
        $entry_ID->[1] //= -1;
        my $start_pos = $list->pos_from_ID( $entry_ID->[0] );
        my $end_pos = $list->pos_from_ID( $entry_ID->[1] );
        return " ! '$entry_ID->[0]' is not a valid position in list '".$list->get_name."', please check --list ".$list->get_name unless $start_pos;
        return " ! '$entry_ID->[1]' is not a valid position in list '".$list->get_name."', please check --list ".$list->get_name unless $end_pos;
        $entry_ID = [$start_pos .. $end_pos];
    } else {
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless $list->pos_from_ID( $entry_ID );
        $entry_ID = [$entry_ID];
    }
    my $ret = '';
    for my $ID (reverse @$entry_ID){
        my $entry = $list->remove_entry( $ID );
        my $entry_address = App::Goto::Dir::Parse::is_position( $ID ) ? $list->get_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$ID
                                                                      : $list->get_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$ID;
        $ret .= " - removed entry '$entry_address' ".App::Goto::Dir::Format::text($entry->full_dir(), 30)."\n";
        $data->set_special_entry( $_, $entry ) for qw/move vm/;
    }
    chomp($ret);
    $ret;
}

sub move_entry {
    my ($source, $target) = @_;
    $source_list_name //= $data->get_current_list_name;
    $source_entry_ID  //= $config->{'entry'}{'position_default'};
    $target_list_name //= $data->get_current_list_name;
    $target_entry_ID  //= $config->{'entry'}{'position_default'};
    my $source_list  = $data->get_list( $source_list_name );
    my $target_list  = $data->get_list( $target_list_name );
    return " ! source list named '$source_list_name' does not exist, please check --list-lists" unless ref $source_list;
    return " ! target list named '$target_list_name' does not exist, please check --list-lists" unless ref $target_list;
    return " ! source list of --move has to be regular or same as target, please check --list-lists" if ref $source_list->is_special and $source_list ne $target_list;
    return " ! target list of --move has to be regular or same as source, please check --list-lists" if ref $target_list->is_special and $source_list ne $target_list;
    my $target_pos = $target_list->pos_from_ID( $target_entry_ID, 'target' );
    return " ! target position or name '$target_entry_ID' does not exist in list '$target_list_name'" unless $target_pos;
    if (ref $source_entry_ID eq 'ARRAY'){
        $source_entry_ID->[0] //= 1;
        $source_entry_ID->[1] //= -1;
        my $start_pos = $source_list->pos_from_ID( $source_entry_ID->[0] );
        my $end_pos = $source_list->pos_from_ID( $source_entry_ID->[1] );
        return " ! '$source_entry_ID->[0]' is not a valid position in source list '".$source_list->get_name."', check --list ".$source_list->get_name unless $start_pos;
        return " ! '$source_entry_ID->[1]' is not a valid position in source list '".$source_list->get_name."', check --list ".$source_list->get_name unless $end_pos;
        $source_entry_ID = [$start_pos .. $end_pos];
    } else {
        return " ! source position or name '$source_entry_ID' does not exist in list '".$source_list->get_name."', check --list ".$source_list->get_name
            unless $source_list->pos_from_ID( $source_entry_ID );
        $source_entry_ID = [$source_entry_ID] ;
    }
    my $target_address = App::Goto::Dir::Parse::is_position( $target_entry_ID ) ? $target_list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$target_entry_ID
                                                                                : $target_list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$target_entry_ID;
    my $ret = '';
    for my $ID (reverse @$source_entry_ID){
        my $entry = $source_list->remove_entry( $ID );
        my $insert_error = $target_list->insert_entry( $entry, $target_entry_ID );
        return "$ret ! $insert_error" unless ref $insert_error;
        my $src_address = App::Goto::Dir::Parse::is_position( $ID ) ? $source_list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$ID
                                                                    : $source_list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$ID;
        $ret .= " - moved entry '$src_address' to '$target_address' ".App::Goto::Dir::Format::text($entry->full_dir(), 30)."\n";
        $data->set_special_entry( $_, $entry, $target_list_name ) for qw/remove rem rm/;
    }
    chomp($ret);
    $ret;
}

sub copy_entry {
    my ($source, $target) = @_;
    $source_entry_ID  //= $config->{'entry'}{'position_default'};
    $target_entry_ID  //= $config->{'entry'}{'position_default'};
    $source_list_name //= App::Goto::Dir::Parse::is_name( $source_entry_ID ) ? $data->get_special_list_names('all') : $data->get_current_list_name ;
    $target_list_name //= $data->get_current_list_name;
    return " ! source and target list have to be different, both are '$source_list_name'" if $source_list_name eq $target_list_name;
    my $source_list  = $data->get_list( $source_list_name );
    my $target_list  = $data->get_list( $target_list_name );
    return " ! source list named '$source_list_name' does not exist, please check --list-lists" unless ref $source_list;
    return " ! target list named '$target_list_name' does not exist, please check --list-lists" unless ref $target_list;
    return " ! target list of --copy has to be regular, check --list-lists" if ref $target_list->is_special;
    my $target_pos = $target_list->pos_from_ID( $target_entry_ID, 'target' );
    return " ! position or name '$target_entry_ID' does not exist in list '$target_list_name'" unless $target_pos;
    if (ref $source_entry_ID eq 'ARRAY'){
        $source_entry_ID->[0] //= 1;
        $source_entry_ID->[1] //= -1;
        my $start_pos = $source_list->pos_from_ID( $source_entry_ID->[0] );
        my $end_pos = $source_list->pos_from_ID( $source_entry_ID->[1] );
        return " ! '$source_entry_ID->[0]' is not a valid position in source list '".$source_list->get_name."', check --list ".$source_list->get_name unless $start_pos;
        return " ! '$source_entry_ID->[1]' is not a valid position in source list '".$source_list->get_name."', check --list ".$source_list->get_name unless $end_pos;
        $source_entry_ID = [$start_pos .. $end_pos];
    } else {
        return " ! source position or name '$source_entry_ID' does not exist in list '".$source_list->get_name."', check --list ".$source_list->get_name
            unless $source_list->pos_from_ID( $source_entry_ID );
        $source_entry_ID = [$source_entry_ID] ;
    }
    my $target_address = App::Goto::Dir::Parse::is_position( $target_entry_ID ) ? $target_list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$target_entry_ID
                                                                                : $target_list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$target_entry_ID;
    my $ret = '';
    for my $ID (reverse @$source_entry_ID){
        my $entry = $source_list->get_entry( $ID );
        my $insert_error = $target_list->insert_entry( $entry, $target_entry_ID );
        return "$ret ! $insert_error" unless ref $insert_error;
        my $src_address = App::Goto::Dir::Parse::is_position( $ID ) ? $source_list_name.$config->{'syntax'}{'sigil'}{'entry_position'}.$ID
                                                                    : $source_list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$ID;
        $ret .= " - copied entry '$src_address' to '$target_address' ".App::Goto::Dir::Format::text($entry->full_dir(), 30)."\n";
        $data->set_special_entry( $_, $entry, $target_list_name ) for qw/copy cp/;
    }
    chomp($ret);
    $ret;
}

sub dir_entry {
    my ($entry, $new_dir) = @_;
    return " ! missing directory path as argument" unless defined $new_dir;
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name //= App::Goto::Dir::Parse::is_name( $entry_ID ) ? $data->get_special_list_names('all') : $data->get_current_list_name;
    my $entry;
    if (ref $list_name){
        $entry = $data->get_special_entry( $entry_ID );
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' does not exist, please check --list-special" unless ref $entry;
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' is currently empty" unless $entry->dir;
    } else {
        my $list  = $data->get_list( $list_name );
        return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
        $entry = $list->get_entry( $entry_ID );
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless ref $entry;
    }
    my ($all, $stale) = $data->get_special_lists(qw/all stale/);
    my $sibling_pos = $all->pos_from_dir( $new_dir );
    if ($sibling_pos){
        return " ! there is already an entry with dir '$new_dir'" if $config->{'entry'}{'prefer_in_dir_conflict'} eq 'old';
        my $sibling = $all->get_entry( $sibling_pos );
        $data->get_list($_)->remove_entry( $sibling ) for $sibling->member_of_lists ;
    }
    my $old_dir = $entry->full_dir;
    $entry->redirect( $new_dir );
    $data->get_list( $_)->refresh_reverse_hashes for $entry->member_of_lists;
    $data->set_special_entry( 'dir', $entry, $list_name);
    my $address = App::Goto::Dir::Parse::is_name( $entry_ID ) ?            $config->{'syntax'}{'sigil'}{'entry_position'}.$entry_ID
                                                              : $list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$entry_ID;
    " - chanded directory of entry $address from '$old_dir' to '$new_dir'";
}
sub redir_entry {
    my ($old_path, $new_path) = @_;
    return " ! need two directory paths as arguments" unless defined $new_path;
    return " ! '$new_path' is not an accessible directory" if $config->{'entry'}{'dir_exists'} and not -d $new_path;
    $old_path = App::Goto::Dir::Data::Entry::_expand_home_dir($old_path);
    $new_path = App::Goto::Dir::Data::Entry::_expand_home_dir($new_path);
    my $all = $data->get_special_lists('all');
    my $path_length = length $old_path;
    my $ret = "";
    for my $entry ($all->elems){
        my $old_dir = $entry->full_dir;
        next unless substr $old_dir, 0, $path_length eq $old_path;
        my $new_dir = File::Spec->catdir( $new_path, substr $old_dir, $path_length );
        $entry->redirect($new_dir);
        $ret .= ($entry->name ? $entry->name : 'unnamed').$config->{'syntax'}{'sigil'}{'entry_name'}." $old_dir \n";
    }
    $ret = $ret ? " - changed dir '$old_path' to '$new_path' in\n$ret" : " - no entry stores a subdirectory of '$old_path'";
    $data->get_list($_)->refresh_reverse_hashes() for $data->get_all_list_name;
    rename $old_path, $new_path if $config->{'entry'}{'dir_move'};
    $ret .= "\n   and renamed path '$old_path' to '$new_path'" if $config->{'entry'}{'dir_move'};
    $ret;
}

sub name_entry {
    my ($entry, $new_name) = @_;
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name //= App::Goto::Dir::Parse::is_name( $entry_ID ) ? $data->get_special_list_names('all') : $data->get_current_list_name ;
    $new_name //= '';
    my $entry;
    if (ref $list_name){
        $entry = $data->get_special_entry( $entry_ID );
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' does not exist, please check --list-special" unless ref $entry;
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' is currently empty" unless $entry->dir;
    } else {
        my $list  = $data->get_list( $list_name );
        return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
        $entry = $list->get_entry( $entry_ID );
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless ref $entry;
    }
    my ($all, $named) = $data->get_special_lists(qw/all named/);
    my $sibling = $all->get_entry( $new_name );
    if (ref $sibling){
        return " ! there is already an entry named '$new_name'" if $config->{'entry'}{'prefer_in_name_conflict'} eq 'old';
        $sibling->rename( '' );
        $named->remove_entry( $sibling );
        $data->get_list( $_ )->refresh_reverse_hashes for $sibling->member_of_lists;
    }
    my $old_name = $entry->name;
    $entry->rename($new_name);
    $named->insert_entry( $entry ) if $new_name and not $old_name;
    $named->remove_entry( $entry ) if $old_name and not $new_name;
    $data->get_list( $_ )->refresh_reverse_hashes for $entry->member_of_lists;
    $data->set_special_entry( 'name', $entry, $list_name);
    my $address = App::Goto::Dir::Parse::is_name( $entry_ID ) ?            $config->{'syntax'}{'sigil'}{'entry_position'}.$entry_ID
                                                              : $list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$entry_ID;
    " - renamed entry $address from '$old_name' to '$new_name'";
}

sub script_entry {
    my ($entry, $new_script, $file) = @_;
    return " ! need only a single quoted perl script OR a file path as argument" unless defined $new_script and defined $file;
    return " ! file $file does not exists or is not readable" if defined $file and not -r $file;
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name //= App::Goto::Dir::Parse::is_name( $entry_ID ) ? $data->get_special_list_names('all') : $data->get_current_list_name ;
    $new_script //= '';
    my $entry;
    if (ref $list_name){
        $entry = $data->get_special_entry( $entry_ID );
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' does not exist, please check --list-special" unless ref $entry;
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' is currently empty" unless $entry->dir;
    } else {
        my $list  = $data->get_list( $list_name );
        return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
        $entry = $list->get_entry( $entry_ID );
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless ref $entry;
    }
    if (defined $file){
        open my $FH, '<', $file;
        while (<$FH>){
            chomp;
            $new_script .= $_;
        }
    }
    my $old_script = $entry->script;
    $entry->edit( $new_script );
    $data->set_special_entry( 'script', $entry, $list_name );
    my $address = App::Goto::Dir::Parse::is_name( $entry_ID ) ?            $config->{'syntax'}{'sigil'}{'entry_position'}.$entry_ID
                                                              : $list_name.$config->{'syntax'}{'sigil'}{'entry_name'}.$entry_ID;
    " - replaced script of entry $address from '".App::Goto::Dir::Format::text($old_script, 20)."' to '".App::Goto::Dir::Format::text($new_script, 20)."'";
}

sub goto_entry {
    my ($list_name, $entry_ID, $sub_dir) = @_;
    $entry_ID  //= $config->{'entry'}{'position_default'};
    $list_name //= App::Goto::Dir::Parse::is_name( $entry_ID ) ? $data->get_special_list_names('all') : $data->get_current_list_name ;
    $sub_dir //= '';
    my $entry;
    if (ref $list_name){
        $entry = $data->get_special_entry( $entry_ID );
        return " ! special entry named '$config->{syntax}{sigil}{special_entry}$entry_ID' does not exist, please check --list-special" unless ref $entry;
    } else {
        my $list  = $data->get_list( $list_name );
        return " ! list named '$list_name' does not exist, please check --list-lists" unless ref $list;
        $entry = $list->get_entry( $entry_ID );
        return " ! position or name '$entry_ID' does not exist in list '$list_name'" unless ref $entry;
    }
    $data->visit_entry($entry, $sub_dir);
}

1;

