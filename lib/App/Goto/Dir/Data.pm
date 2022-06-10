use v5.18;
use warnings;
no warnings  qw/experimental::smartmatch/;
use feature qw/switch/;
use YAML;
use File::Spec;
use App::Goto::Dir::Data::List;

package App::Goto::Dir::Data;

#### de- constructors ##################################################
sub new {
    my ($pkg, $data) = @_;
    return unless ref $data eq 'HASH';
    my $file = $config->{'file'}{'data'};
    my $sls = $config->{'syntax'}{'sigil'}{'special_list'};
    my %sl_name = map { $_ => $sls.$config->{'list'}{'special_name'}{$_} } keys %{$config->{'list'}{'special_name'}};
    my %sl_desc = map { $sl_name{$_} => $config->{'list'}{'special_description'}{$_}} keys %sl_name;
    my $data = (-r $file) ? YAML::LoadFile($file)
                          : { list => { description => [%sl_desc, 'use'=> 'projects currently worked on', 'idle'=> 'dormant or put back projects'],
                                        current => 'use', sorted_by => 'position', sort_reversed => 0} , entry => [],
                              visits => {last_dir => '',last_subdir => '', previous_dir => '', previous_subdir => ''},  history => [0],  };

    $data->{'entry'} = [ grep { $_->overdue() < $config->{'list'}{'deprecate_bin'} } # scrap long deleted
                         map  { App::Goto::Dir::Data::Entry->restate($_)           } @{ $data->{'entry'} }  ];

    my %sln_tr; # special list name translator in case sigil changed
    for my $list_name (keys %{$data->{'list'}{'description'}}){
        next if substr($list_name, 0, 1) =~ /\w/ or substr($list_name, 0, 1) eq $sls;
        my $new_name = $sls . substr($list_name, 1);
        $data->{'list'}{'description'}{$new_name} = delete $data->{'list'}{'description'}{$list_name};
        $sln_tr{ $list_name } = $new_name;
    }
    my %list;
    for my $entry (@{ $data->{'entry'}}){
        $entry->remove_from_list($sl_name{'new'})   if $entry->age() > $config->{'list'}{'deprecate_new'};
        $entry->remove_from_list($sl_name{'stale'}) if -d $entry->full_dir;
        for my $list_name ($entry->member_of_lists) {
            if (exists $sln_tr{$list_name}){
                $list{ $sln_tr{ $list_name } }[ $entry->get_list_pos($list_name) ] = $entry;
                $entry->remove_from_list($list_name);
            } else {
                $list{$list_name}[ $entry->get_list_pos($list_name) ] = $entry;
            }
        }
    }
    for my $entry (@{ $data->{'entry'}}){
        next if $entry->get_list_pos( $sl_name{'stale'}) or -d $entry->full_dir;
        $entry->add_to_list( $sl_name{'stale'}, 1 );
        push @{ $list{ $sl_name{'stale'} }}, $entry;
    }
    for my $list_name (keys %list) { # create lists with entries
        new_list( $data, $list_name, $data->{'list'}{'description'}{$list_name}, $config->{'entry'}, grep {ref $_} @{$list{$list_name}} );
    }
    for my $list_name (values %sl_name, keys %{$data->{'list'}{'description'}}) { # create empty lists too
        next if exists $data->{'list_object'}{ $list_name };
        new_list( $data, $list_name, $data->{'list'}{'description'}{$list_name}, $config->{'entry'} );
    }
    my $all = $data->{'list_object'}{ $sl_name{'all'} };
    $data->{'special_entry'}{'last'}   = $all->get_entry( $all->pos_from_dir( $data->{'visits'}{'last_dir'} ) );
    $data->{'special_entry'}{'prev'}   = $data->{'special_entry'}{'previous'} =
                                         $all->get_entry( $all->pos_from_dir( $data->{'visits'}{'previous_dir'} ) );
    for my $name (get_special_entry_names()){
        $data->{'special_entry'}{$name} = App::Goto::Dir::Data::Entry->new() unless ref $data->{'special_entry'}{$name};
    }
    $data->{'special_list'} = \%sl_name;
    $data->{'config'} = $config;
    bless $data;
}

sub write {
    my ($self, $config) = @_;
    my $state                = { map { $_ => $self->{$_}} qw/visits list/ }; # history ?
    $state->{'entry'}         = [ map { $_->state } $self->get_special_lists('all')->all_entries ];
    $state->{'list'}{'description'} = { map {$_->get_name => $_->get_description} values %{ $self->{'list_object'} } };
    $state->{'list'}{'current'} = $config->{'list'}{'default_name'} if  $config->{'list'}{'start_with'} eq 'default';

    rename $config->{'file'}{'data'}, $config->{'file'}{'backup'};
    YAML::DumpFile( $config->{'file'}{'data'}, $state );
    open my $FH, '>', $config->{'file'}{'return'};
    print $FH File::Spec->catdir( $self->{'visits'}{'last_dir'}, $self->{'visits'}{'last_subdir'});
}

#### list API ###########################################################
sub new_list {
    my ($self, $list_name, $description, $config, @elems) = @_;
    $self->{'list_object'}{ $list_name } = App::Goto::Dir::Data::List->new( $list_name, $description, $config, @elems );
}
sub remove_list           { delete $_[0]->{'list_object'}{ $_[1] }                    }
sub get_list              { $_[0]->{'list_object'}{$_[1]} if exists $_[0]->{'list_object'}{$_[1]} }
sub list_exists           { defined $_[1] and exists $_[0]->{'list_object'}{$_[1]}    }
sub change_list_name      {
    my ($self, $old_name, $new_name) =  @_;
    return unless $self->list_exists( $old_name ) and not $self->list_exists( $new_name );
    my $list = $self->{'list_object'}{$new_name} = delete $self->{'list_object'}{$old_name};
    $list->set_name( $new_name );
}
sub change_current_list   { $_[0]->{'list'}{'current'} = $_[1] if exists $_[0]->{'list_object'}{$_[1]} }
sub get_current_list      { $_[0]->{'list_object'}{ $_[0]->{'list'}{'current'} }      }
sub get_current_list_name {                         $_[0]->{'list'}{'current'}        }
sub set_current_list_name {                         $_[0]->{'list'}{'current'} = $_[1]}
sub get_all_list_name     { keys %{$_[0]->{'list_object'}}                            }
sub get_special_lists     { my $self = shift; @{ $self->{'list_object'}}{ $self->get_special_list_names(@_) } if @_}
sub get_special_list_names{ my $self = shift; @{ $self->{'special_list'}}{ @_ }       }

#### entry API #########################################################

sub get_special_entry_names{ qw/last previous add delete undelete remove move copy dir name script/ }

sub visit_entry {
    my ($self, $entry, $sub_dir) = @_;
    return $entry unless ref $entry;
    $entry->visit();
    ($self->{'visits'}{'previous_dir'},$self->{'visits'}{'previous_subdir'}) =
        ($self->{'visits'}{'last_dir'},$self->{'visits'}{'last_subdir'});
    $self->{'special_entry'}{'prev'} = $self->{'special_entry'}{'previous'} = $self->{'special_entry'}{'last'};
    $self->{'special_entry'}{'last'} = $entry;
    $self->{'visits'}{'last_dir'} = $entry->full_dir();
    $self->{'visits'}{'last_subdir'} = defined $sub_dir ? $sub_dir : '';
    $entry;
}
sub visit_last_entry     { $_[0]->visit_entry( $_[0]->get_special_entry('last'),  $_[0]->{'visits'}{'last_subdir'} ) }
sub visit_previous_entry { $_[0]->visit_entry( $_[0]->get_special_entry('previous'), $_[0]->{'visits'}{'previous_subdir'} ) }

sub get_special_entry {
    my ($self, $name) = @_;
    return unless exists $self->{'special_entry'}{$name};
    wantarray ? @{$self->{'special_entry'}{$name}} : $self->{'special_entry'}{$name}->[0];
}
sub set_special_entry {
    my ($self, $name, $entry, $list_name) = @_;
    return if ref $entry ne 'App::Goto::Dir::Data::Entry' or not defined $list_name or not exists $self->{'list_object'}{$list_name};
    $self->{'special_entry'}{$name} = [defined $list_name ? $list_name : get_special_lists('all'), $entry];
}

########################################################################
sub undo         { my ($self) = @_; } # TODO
sub redo         { my ($self) = @_; }

1;
