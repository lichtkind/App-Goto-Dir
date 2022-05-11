use v5.18;
use warnings;

package App::Goto::Dir::Format;

sub lists {
    my ($config, $data) = @_;
    my @l = map { [$_, $_->get_name] } map { $data->get_list($_) } sort $data->get_all_list_name();
    my $c = $data->get_current_list_name();
    my $sig = $config->{'syntax'}{'sigil'}{'special_list'};
    my $nl = $config->{'list'}{'name_length_max'} +1;

    my $ret = "  all list on Goto::Dir (name, elements, description, c = current):\n".
              " ------------------------------------------------------------------\n";
    $ret .= sprintf ("  %-".$nl."s. %s . %02u . %s\n",
             (substr($_->[1], 0, 1) eq $sig ? '' : ' ' ).$_->[1], $_->[1] eq $c ? 'c': '.', $_->[0]->elems, $_->[0]->get_description ) for @l;
    $ret."\n";
}

sub special_entries {
    my ($config, $data) = @_;
    my @l = map { [$_, $_->get_name] } map { $data->get_list($_) } sort $data->get_all_list_name();
    my $c = $data->get_current_list_name();
    my $sig = $config->{'syntax'}{'sigil'}{'special_entry'};
    my $space = '. 'x(3+int($config->{'list'}{'name_length_max'}/2));
    my $ret = "  special entries on Goto::Dir (start with $sig):\n".
              " ---------------------------------------------\n";
    $ret .= '  '.$sig.$_.substr($space, length $_).$data->get_special_entry($_)->dir."\n" for $data->get_special_entry_names;
    $ret."\n";
}

sub list_entries {
    my ($config, $data, @l) = @_;
    join '', map {entries($config, $data, $_) } @l;
}
sub entries {
    my ($config, $data, $list_name) = @_;
    return 'need a name of an existing list' unless defined $list_name;
    my $list = $data->get_list($list_name);
    return "list '$list_name' unknown" unless ref $list;
    $data->set_current_list_name( $list_name );
    my $pos = 1;
    my @el = map {{el => $_, pos => $pos++}} $list->all_entries;
    my $sorted = $data->{'list'}{'sorted_by'};
    @el = sort { $a->{'el'}->full_dir     cmp $b->{'el'}->full_dir     } @el if $sorted eq 'dir';
    @el = sort { $a->{'el'}->name         cmp $b->{'el'}->name         } @el if $sorted eq 'name';
    @el = sort { $a->{'el'}->script       cmp $b->{'el'}->script       } @el if $sorted eq 'script';
    @el = sort { $b->{'el'}->visit_count  <=> $a->{'el'}->visit_count  } @el if $sorted eq 'visits';
    @el = sort { $a->{'el'}->visit_stamp  <=> $b->{'el'}->visit_stamp  } @el if $sorted eq 'last_visit';
    @el = sort { $a->{'el'}->create_stamp <=> $b->{'el'}->create_stamp } @el if $sorted eq 'created';
    @el = reverse @el if $data->{'list'}{'sort_reversed'};
    my $nl = $config->{'entry'}{'name_length_max'} + 1;
    my $rev = $data->{'list'}{'sort_reversed'} ? 'reversed '  : '';
    my $ret = "  entries of list '$list_name' (pos., name, "
             .($sorted eq 'visits'     ? 'visits, ':
               $sorted eq 'last_visit' ? 'time, '  :
               $sorted eq 'created'    ? 'time, '  : '')."dir) sorted by $rev$sorted:";
    $ret .= "\n ".('-'x (length($ret) -1))."\n";
    my $max_dir_length = 70 - $config->{'entry'}{'name_length_max'};
    $max_dir_length -=  4 if $sorted eq 'visits';
    $max_dir_length -= 22 if $sorted eq 'last_visit' or $sorted eq 'created';
    $max_dir_length -= 35 if $sorted eq 'script';
    map { $_->{'dir'} = text( $_->{'el'}->dir, $max_dir_length) } @el;
    my $formstart = "  [%02u]  %-".$nl."s ";
    if    ($sorted eq 'visits')    {$ret.= sprintf ("$formstart%02u  %s\n", $_->{'pos'}, $_->{'el'}->name, $_->{'el'}->visit_count, $_->{'dir'}) for @el }
    elsif ($sorted eq 'last_visit'){$ret.= sprintf ("$formstart%s  %s\n", $_->{'pos'}, $_->{'el'}->name, $_->{'el'}->visit_time, $_->{'dir'}) for @el }
    elsif ($sorted eq 'created')   {$ret.= sprintf ("$formstart%s  %s\n", $_->{'pos'}, $_->{'el'}->name, $_->{'el'}->create_time, $_->{'dir'}) for @el }
    elsif ($sorted eq 'script')    {$ret.= sprintf ("$formstart %-31s %s\n", $_->{'pos'}, $_->{'el'}->name, $_->{'dir'},  text($_->{'el'}->script, 35)) for @el }
    else                           {$ret.= sprintf ("$formstart %s\n", $_->{'pos'}, $_->{'el'}->name, $_->{'dir'} ) for @el }
    $ret."\n";
}

sub text {
    my ($text, $length) = @_;
    return '' unless defined $text;
    return $text if length $text < $length;
    substr($text, 0, int ($length/2)-1) . '..' . substr $text, -int ($length/2);
}

my %sopt;
sub set_sort {
    my ($config, $data, $criterion) = @_;
    my @opt = keys %{$config->{'syntax'}{'option_shortcut'}{'sort'}};

    $criterion = $config->{'list'}{'sort_default'} if not defined $criterion or $criterion eq 'default';
    my $reverse = 0;
    if (substr( $criterion, 0, 1) eq '!') {
        $reverse = 1;
        $criterion = substr $criterion, 1;
    }
    $criterion = $App::Goto::Dir::Config::option_name{ $criterion } if exists $App::Goto::Dir::Config::option_name{ $criterion }
                                                                          and $App::Goto::Dir::Config::option_name{ $criterion };
    return " ! unknown list sorting criterion: '$criterion', use [!]".join '|', @opt, 'default'
        unless exists $config->{'syntax'}{'option_shortcut'}{'sort'}{$criterion};
    $data->{'list'}{'sorted_by'} = $criterion;
    $data->{'list'}{'sort_reversed'} = $reverse;
    " - set list sorting criterion to '$criterion' ".($reverse ? '(reversed)' : '');
}

1;
