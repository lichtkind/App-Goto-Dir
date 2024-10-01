use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Command::Parser;

my ($config, $data);
my %command_tr = ( 'del' => 'delete',
                 'undel' => 'undelete',
                   'rem' => 'remove',
                    'rm' => 'remove',
                    'mv' => 'move',
                    'cp' => 'copy',
              'del-list' => 'delete-list',
            'descr-list' => 'describe-list',
);
my %command = ('add' => [0, 0, 0, 0, 0], # i: 0 - has option ;
            'delete' => [0, 0,       1], #    1 - n-1 arg required?
          'undelete' => [0, 0, 0,    0], #    n - last arg is slurp
            'remove' => [0, 0,       1],
              'move' => [0, 0, 1,    0],
              'copy' => [0, 0, 1,    0],
              'name' => [0, 0, 0,    0],
            'script' => [0, 0, 1,    0],
               'dir' => [0, 0, 1,    0],
             'redir' => [0, 1, 0, 1, 0],
              'goto' => [0, 1,       0],
              'help' => [3, 0       -1],
              'sort' => [6],             # no args, just 6 options
              'list' => [0, 0,       1],
        'list-lists' =>  0,
      'list-special' =>  0,
          'add-list' => [0, 1,       0],
       'delete-list' => [0, 1,       0],
         'name-list' => [0, 1, 1,    0],
     'describe-list' => [0, 1, 1,    0],
);
my %command_argument = ( 'add' => [qw/path named_entry target/],
                        delete => ['source'],
                      undelete => ['list_elems', 'reg_target'],
                        remove => ['reg_source'],
                          move => ['reg_source', 'target'],
                          copy => ['source',  'reg_target'],
                          name => ['target', 'named_entry'],
                           dir => ['target', 'path'],
                         redir => ['path', '<<', 'path'],
                        script => ['target', 'text'],
                          help => ['command'],
                          list => ['list_name'],
                    'add-list' => ['list_name'],
                 'delete-list' => ['list_name'],
                   'name-list' => ['list_name', 'list_name'],
               'describe-list' => ['list_name', 'text'],
);

my $sig = { short_command => '-', entry_name => ':',
                     help => '?', entry_position => '^',
                     file => '<', special_entry => '+', special_list => '@', };
my $rule = {
    ws    => '\s*',
    pos   => '-?\d+',
    name  => '[a-zA-Z]\w*',
    text  => '\'(?<text_content>.*(?<!\\))\'',
};

sub init {
    ($config, $data)  = @_;
    $sig = { map {$_ => quotemeta $config->{'syntax'}{'sigil'}{$_}} keys %{$config->{'syntax'}{'sigil'}}};
    my $slist_name = $config->{'list'}{'special_name'};
    my @cmd = (keys %command, keys %command_tr);
    $rule->{'dir'}              = '(?<dir>[/\\\~]\S*)';
    $rule->{'file'}             = '(?:'.$sig->{file}.'?'.$rule->{dir}.'|'.$sig->{file}.$rule->{text}.')';

    $rule->{'reg_list_name'}    = '(?<list_name>'.$rule->{name}.')';
    $rule->{'list_name'}        = '(?<list_name>(?<special_list>'.$sig->{special_list}.')?'.$rule->{reg_list_name}.')';
    $rule->{'entry_name'}       = '(?<entry_name>'.$rule->{name}.')';
    $rule->{'entry_pos'}        = '(?<entry_pos>'.$rule->{pos}.')';
    $rule->{'named_entry'}      = '(?:'.$sig->{entry_name}.'?'.$rule->{entry_name}.')';
    $rule->{'special_entry'}    = '(?:'.$sig->{special_entry}.'(?<special_entry>'.$rule->{name}.'))';
    $rule->{'name_group'}       = '(?<name_group>(?:'.$sig->{entry_name}.$rule->{name}.')+)';
    $rule->{'pos_group'}        = '(?<pos_group>(?:'.$sig->{entry_position}.$rule->{name}.')+)';
    $rule->{'pos_range'}        = '(?:(?<start_pos>'.$rule->{pos}.')?\.\.(?<end_pos>'.$rule->{pos}.'))';

    $rule->{'entry_name_adr'}   = '(?:(?:'.$rule->{list_name}.'?'.$sig->{entry_name}.')?'.$rule->{entry_name}.')';
    $rule->{'entry_pos_adr'}    = '(?:(?:'.$rule->{list_name}.'?'.$sig->{entry_position}.')?'.$rule->{entry_pos}.')';
    $rule->{'entry_name_group'} = '(?:'.$rule->{list_name}.'?'.$rule->{name_group}.')';
    $rule->{'entry_pos_group'}  = '(?:'.$rule->{list_name}.'?'.$rule->{pos_group}.')';
    $rule->{'entry_pos_range'}  = '(?:(?:'.$rule->{list_name}.'?'.$sig->{entry_position}.')?'.$rule->{pos_range}.')';
    $rule->{'entry'}            = '(?<entry>'.$rule->{special_entry}.'|'.$rule->{entry_name_adr}.'|'.$rule->{entry_pos_adr}.')'; # any single entry
    $rule->{'reg_name_adr'}     = '(?:(?:'.$rule->{reg_list_name}.'?'.$sig->{entry_name}.')?'.$rule->{entry_name}.')';
    $rule->{'reg_pos_adr'}      = '(?:(?:'.$rule->{reg_list_name}.'?'.$sig->{entry_position}.')?'.$rule->{entry_pos}.')';
    $rule->{'reg_name_group'}   = '(?:(?:'.$rule->{reg_list_name}.'?'.$rule->{name_group}.')';
    $rule->{'reg_pos_group'}    = '(?:(?:'.$rule->{reg_list_name}.'?'.$rule->{pos_group}.')';
    $rule->{'reg_pos_range'}    = '(?:(?:'.$rule->{reg_list_name}.'?'.$sig->{entry_position}.')?'.$rule->{pos_range}.')';

    $rule->{'list_elem'}        = '(?:'.$sig->{entry_position}.'?'.$rule->{entry_pos}.'|'.$sig->{entry_name}.'?'.$rule->{entry_name}.')';
    $rule->{'list_elems'}       = '(?:'.$rule->{list_elem}.'|'.$sig->{entry_position}.'?'.$rule->{pos_range}.'|'.$rule->{pos_group}.'|'.$rule->{name_group}.')';
    $rule->{'reg_source'}       = $rule->{reg_name_adr}.'|'.$rule->{reg_pos_adr}.'|'.$rule->{reg_name_group}.'|'.$rule->{reg_pos_group}.'|'.$sig->{entry_position}.'?'.$rule->{reg_pos_range}.'|'.$rule->{special_entry}; #special dont have to be regular
    $rule->{'reg_target'}       = $rule->{reg_name_adr}.'|'.$rule->{reg_pos_adr}.'|'.$rule->{special_entry};
    $rule->{'source'}           = $rule->{entry}.'|'.$rule->{entry_name_group}.'|'.$rule->{entry_pos_group}.'|'.$rule->{entry_pos_range};
    $rule->{'target'}           = $rule->{'entry'};
    $rule->{'path'}             = $rule->{entry}.'?(?:'.$rule->{text}.'|'.$rule->{dir}.')';
    $rule->{'command'}          = '(?:--)?(?:'.(join '|',@cmd).')';
}

sub is_dir      { defined $_[0] and $_[0] =~ '^'.$rule->{'dir'}.'$' }
sub is_name     { defined $_[0] and $_[0] =~ '^'.$rule->{'name'}.'$' }
sub is_position { defined $_[0] and $_[0] =~ '^'.$rule->{'pos'}.'$' }
sub args {
    my (@token) = @_;
    my @comands = ();
    my $sig = $config->{'syntax'}{'sigil'};
    for my $token (@token){
        return [" ! missing a command",['--help']] unless $token;
        my $cmd;
        if (length $token == 1){
            if ($token =~ /\W/){
                (push @comands, ['goto', $sig->{'special_entry'}.'last']),next if $token eq $config->{'syntax'}{'special_entry'}{'last'};
                (push @comands, ['goto', $sig->{'special_entry'}.'prev']),next if $token eq $config->{'syntax'}{'special_entry'}{'previous'};
                return " ! there is no special shortcut named '$token'" unless defined $cmd;
            }
        }
        my $short_cmd = substr($token, 1, 1);
        if (substr($token, 0, 1) eq $config->{'syntax'}{'sigil'}{'command'} and $short_cmd =~ /\w/){
            my $cmd = $App::Goto::Dir::Config::command_shortcut{ $short_cmd };
            if (length($token) > 3 and substr($token, 2,1) eq '-'){
                my $lshort_cmd = substr($token,1,3);
                my $cmdl = $App::Goto::Dir::Config::command_shortcut{ $lshort_cmd };
                ($short_cmd, $cmd) = ($lshort_cmd, $cmdl) if defined $cmdl;
            }
            return " ! there is no command shortcut $config->{'syntax'}{'sigil'}{'command'}$short_cmd, please check --help=commands or -hc" unless defined $cmd;
            if (exists $config->{'syntax'}{'option_shortcut'}{$cmd} and length $token > length($short_cmd) + 1) {
                my $opt = substr( (length($short_cmd) + 1), 1);
                return " ! command shortcut $config->{'syntax'}{'sigil'}{'command'}$short_cmd ($cmd) has not option, please check --help $config->{'syntax'}{'sigil'}{'command'}$short_cmd "
                    unless defined $App::Goto::Dir::Config::option_shortcut{$cmd}{$opt};
                $token = "--$cmd=$opt";
            }
            unshift @token, substr($token, 2);
            $token = "--$cmd";
        }
        if ( substr($token,0,2) eq '--' ){
            my $cmd_name = substr $token, 2;
            my @opt = split '=', $cmd_name;
            if (@opt > 1){
                $opt[0] = $command_tr{ $opt[0] } if exists $command_tr{ $opt[0] };
                return " ! there is no command '$opt[0]', please check --help=commands or -hc" unless exists $command{ $opt[0] };
                return " ! only one command option (--command=option) is allowed" if @opt > 2;
                return " ! command '$opt[0]' has no options" unless exists $config->{'syntax'}{'option_shortcut'}{$opt[0]};
                return " ! command '$opt[0]' has no option '$opt[1]' (partial optio names allowed if they identify option)"
                    unless exists $App::Goto::Dir::Config::option_name{$opt[0]}{$opt[1]};
                $opt[1] = $App::Goto::Dir::Config::option_name{$opt[0]}{$opt[1]};
                push @comands, \@opt;
                next;
            }
            $cmd_name = $command_tr{$cmd_name} if exists $command_tr{$cmd_name};
            return " ! there is no command '$cmd', please check --help=commands or -hc" unless exists $command{$cmd_name};
            return ['help', "--$cmd_name"] if ref $command{$cmd_name} and $command{$cmd_name}[0]; # expected option but not found one
            push @comands, [$cmd_name];
            next if $command{$cmd_name} == 0 or @{$command{$cmd_name}} == 1; # no arguments expected

            for my $arg_nr (0 .. $#{$command_argument{$cmd_name}}){
                my $arg_type = $command_argument{$cmd_name}[$arg_nr];
                my $arg_required = $command{$cmd_name}[$arg_nr+1];
                my $arg_slurp = (($_ == $#{$command_argument{$cmd_name}}) and $command{$cmd_name}[-1]);
                unless (@token){
                    if ($arg_required) { return " ! command $cmd_name is missing argument number $arg_nr: <$arg_type>, plesse check --help $cmd_name" }
                    else               { push @{$comands[-1]}, undef; next }
                }
                my $argument = shift @token;
                my $match = exists $rule->{ $arg_type } ? $argument =~ $rule->{ $arg_type }
                                                        : $argument =~ /$arg_type/;
                unless ($match){
                    if ($arg_required) { return " ! command $cmd_name has missing or malformed argument <$arg_type>, plesse check --help $cmd_name" }
                    else               { push @{$comands[-1]}, undef; unshift @token, $argument; next } # put back unmatched token
                }
                unless (exists $rule->{$arg_type}){
                    push @{$comands[-1]}, $match;
                    next;
                }
                my $arg_value;
                if    ($arg_type eq 'path')       {$arg_value = get_path  }
                elsif ($arg_type eq 'source')     {$arg_value = get_entry }
                elsif ($arg_type eq 'reg_source') {$arg_value = get_entry }
                elsif ($arg_type eq 'target')     {$arg_value = get_entry }
                elsif ($arg_type eq 'reg_target') {$arg_value = get_entry }
                elsif ($arg_type eq 'list_elems') {$arg_value = get_list_elems()   }
                elsif ($arg_type eq 'named_entry'){$arg_value = $+{'entry_name'}   }
                elsif ($arg_type eq 'list_name')  {$arg_value = $match    }
                elsif ($arg_type eq 'text')       {$arg_value = $+{'text_content'} }
                elsif ($arg_type eq 'command')    {$arg_value = $match    }
                else                              {$arg_value = $match    } # ?
                return $arg_value->{'error'} if ref $arg_value eq 'HASH';
                push @{$comands[-1]}, $arg_value;
                if ($arg_slurp){
                    while (@token){
                        my $argument = shift @token;
                        my $match = $argument =~ $rule->{ $arg_type };
                        my $arg_value;
                        if    ($arg_type eq 'source')     {$arg_value = get_entry }
                        elsif ($arg_type eq 'reg_source') {$arg_value = get_entry }
                        elsif ($arg_type eq 'list_name')  {$arg_value = $match }
                        elsif ($arg_type eq 'command')    {$arg_value = $match }
                        else                              {  }

                        if ($match){ return $arg_value->{'error'} if ref $arg_value eq 'HASH';
                                     push @{$comands[-1]}, $arg_value  }
                        else       { unshift @token, $argument; last }
                    }
                }
            }
        } else {
            if ($token =~ $rule->{'path'}) { my $path = get_path();
                                             return $path->{'error'} if ref $path eq 'HASH';
                                             push @comands, ['goto', $path]  }
            else                           { return " ! malformed dir entry adress: $token" }
        }
    }
    \@comands;
}


sub get_path {
    my $entry =  $+{'entry'} ?  get_entry( 'path') : '';
    return $entry if ref $entry eq 'HASH';
    $dir = (ref $entry eq 'ARRAY') ? File::Spec->catdir( $entry->[0]->full_dir, $entry->[1] )
                                   : ref $entry ? $entry->full_dir : '';
    $dir = File::Spec->catdir($dir, $+{'dir'}) if $+{'dir'};
    $dir = File::Spec->catdir($dir, $+{'text_content'}) if $+{'text_content'};
    $dir;
}
sub get_entry {
    my $mode = shift;
    if ($+{'special_entry'}){
        my $entry = $data->get_special_entry( $+{'special_entry'} );
        return {error => " ! there is no special entry '$sig->{special_entry}'"} unless ref $entry;
        return [@{ $data->get_special_entry( $+{'special_entry'} }];
    } else {
        my $list = $+{'list_name'} ? $data->get_list( $+{'list_name'} ) :
                    $mode eq 'path'? $data->get_special_lists('all')    : $data->get_current_list;
        return { error => " ! there is no list '$+{list_name}'"} unless ref $list;
        my $elemind = get_list_elems();
        $elemind = [$elemind] unless ref $elemind;
        my $elems = [];
        for my $index (@$elemind){
            my $entry = $list->get_entry( $index );
            unless (ref $entry){
                return " ! there is no entry on position '$index' in list '".$list->get_name."'" if $+{'entry_pos'} or $+{'start_pos'} or $+{'pos_group'};
                return " ! there is no entry named '$+{entry_name}' in list '".$list->get_name."'" if $+{'entry_name'} or $+{'name_group'};
            }
            push @$elems, $entry;
        }
        [$list, $elems]
    }
}
sub get_list_elems {
    return $+{'entry_pos'}                    if $+{'entry_pos'};
    return $+{'entry_name'}                   if $+{'entry_name'};
    return [$+{'start_pos'} .. $+{'end_pos'}] if $+{'start_pos'};
    if ($+{'pos_group'}) {
        my @pos = split $sig->{'entry_position'}, $+{'pos_group'};
        shift @pos; return \@pos;
    }
    if ($+{'name_group'}){
         my @name = split $sig->{'entry_name'}, $+{'name_group'};
        shift @name; return \@name
    }
}

1;
