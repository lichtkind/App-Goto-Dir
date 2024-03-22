use v5.18;
use warnings;

use App::Goto::Dir::Data::List;

package App::Goto::Dir::Data;

my %special_list = (new  => 'recently created directory entries',
                    bin  => 'deleted but not yet discarded entries',
                    all  => 'all entries, even the deleted',
                    now  => 'recently visited entries, without deleted',
                    named =>'entries with name, without deleted',
                    broken => 'entries with not existing directories, not deleted',);
my %special_entry = (last => 'entry last visited',
                     prev => 'entry second last visited',
                     add  => 'last entry created',
                     del  => 'last entry deleted',
                     name => 'last entry named',
                     move => 'last entry copied, moved or removed',);
#### de- constructors ##################################################
sub new {
    my ($pkg) = @_;
    my $self = { list => {}, current_list => 'all', entry_by_dir => {}, entry_by_name => {}, special_entry => {},
                 undo_stack => [], redo_stack => [], config => {
                     entry => { discard_deleted_in_days => 30,
                                see_as_new_in_days => 40,
                                overwrite_names => 0,
                                name_length_max => 6, },
                     list => { default_insert_position => -1,
                               start_with => '*current',
                         },
                } };
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new($_, $special_list{$_}, 1, []) for keys %special_list;
    $self->{'special_entry'}{$_} = '' for keys %special_entry;
    bless $self;
}

sub restate {
    my ($pkg, $state, $config) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'list'} eq 'HASH' and exists $state->{'current_list'};
    my $self = { list => {}, current_list => '',
                 entry_by_dir => {}, entry_by_name => {}, special_entry => {},
                 undo_stack => [], redo_stack => [] };
    $self->{'current_list'} = $state->{'current_list'};
    my @entries = grep { !$_->is_expired( $config->{'entry'}{'discard_deleted_in_days'} ) }
                  map { App::Goto::Dir::Data::Entry->restate($_) } @{$state->{'entry'}};
    map { $self->{'entry_by_name'}{$_->name} = $_ if $_->name } @entries;
    map { $self->{'entry_by_dir'}{$_->dir} = $_ if $_->dir } @entries;
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new (
                              $_, $state->{'list'}{$_},
                              ((exists $special_list{$_}) ? 1 : 0), \@entries ) for keys %{$state->{'list'}};
    $self->{'list'}{'broken'}->empty_list();
    map { $self->{'list'}{'broken'}->insert_entry( $_, -1) if $_->is_broken } @entries;
    $self->{'special_entry'}{$_} = $state->{'special_entry'}{$_}
                                 ? $self->{'entry_by_dir'}{$_} : '' for keys %special_entry;
    bless $self;
}

sub state {
    my ($self, $state) = (shift, {entry => []});
    $state->{'current_list'} = $self->{'current_list'};
    $state->{'list'}{$_} = $self->{'list'}{$_}->description for keys %{$self->{'list'}};
    push @{$state->{'entry'}}, $_->state for $self->all_entries;
    $state->{'special_entry'}{$_} = (ref $self->{'special_entry'}{$_})
                                  ? $self->{'special_entry'}{$_}->dir : '' for keys %special_entry;
    $state;
}

sub get_config  { $_[0]->{'config'} }
sub set_config  { $_[0]->{'config'} = $_[1] if ref $_[1] eq 'HASH' }

#### list API ###########################################################
sub list_exists  { (defined $_[1] and exists $_[0]->{'list'}{$_[1]}) ? 1 : 0 }
sub get_list     { $_[0]->{'list'}{$_[1]} if list_exists($_[1]) }
sub get_list_or_current { $_[0]->get_list($_[1]) // $_[0]->get_current_list}
sub is_list_special { (defined $_[1] and exists $special_list{$_[1]}) ? 1 : 0 }
sub new_list {
    my ($self, $list_name, $description, @elems) = @_;
    return 'need a list name' unless defined $list_name and $list_name;
    return 'list already exists' if exists $self->{'list'}{ $list_name };
    $self->{'list'}{ $list_name } = App::Goto::Dir::Data::List->new( $list_name, $description, 0, [@elems] );
}
sub remove_list  {
    my ($self, $list_name) = @_;
    return if not exists $self->{'list'}{ $list_name } or $self->{'list'}{ $list_name }->is_special;
    $self->{'list'}{ $list_name }->empty_list;
    delete $self->{'list'}{ $list_name };
}

sub get_current_list      { $_[0]->{'list'}{ $_[0]->{'current_list'} }   }
sub set_current_list      { $_[0]->{'current_list'} = $_[1] if $_[0]->list_exists( $_[1] ) }
sub report                { listing of all lists
    my $self = shift;
    my $report = " - listing of all lists :\n";
    my @order = sort { $self->{'list'}[$a]->name cmp $self->{'list'}[$b]->name }
                     0 .. $#{$_[0]->{'list'}};

    for my $i (@order){
        my $list = $self->{'list'}[$i-1];
        $report .= sprintf "  [%02u]  %6s %1s %s\n", $i, $list->name ,
                                                    ($list->is_special) ? '*' : ' ',
                                                     $list->description;
    }
    $report
}

#### entry API #########################################################
sub all_entries      { @{$_[0]->{'entry_by_dir'}} }
sub entry_by_dir     { $_[0]->{'entry_by_dir'} { $_[1] } if defined $_[1] } # by normalized directory
sub entry_by_name    { $_[0]->{'entry_by_name'}{ $_[1] } if defined $_[1] }
sub special_entry    { $_[0]->{'special_entry'}{ $_[1] } if defined $_[1] }
sub get_entry_by_pos {
    my ($self, $list, $pos) = @_;
    $list = $self->get_list_or_current( $list );
    $list->get_entry_by_pos( $pos ) if ref $list;
}

sub new_entry {
    my ($self, $dir, $name, $list, $pos) = @_;
    my $all = $self->{'list'}{'all'};
    return 'dir is already part of an entry' if ref $all->get_entry_by_property('dir', $dir);
    $name //= '';
    if (ref $self->entry_by_name( $name )
        and $self->{'config'}{'entry'}{'overwrite_names'}) { $self->rename_entry( $name, 'all', '') }
    else                                                   { $name = '' }

    my $entry = App::Goto::Dir::Data::Entry->new( $dir, $name );
    $all->insert_entry( $entry, $self->_pos_for_list('all', $list, $pos) );
    $self->{'list'}{'new'}->insert_entry( $entry, $self->_pos_for_list('new', $list, $pos) );
    $self->{'list'}{'named'}->insert_entry( $entry, $self->_pos_for_list('named', $list, $pos) ) if $name;
    $self->{'list'}{'broken'}->insert_entry( $entry, $self->_pos_for_list('broken', $list, $pos) ) if $entry->is_broken;

    $list = $self->get_list_or_current( $list );
    return $entry if not ref $list or $list->has_entry( $entry );
    $list->insert_entry( $entry, $pos // $self->{'config'}{'list'}{'default_insert_position'} );
}

sub rename_entry {
    my ($self, $list, $ID, $new_name) = @_;
    return 'missing entry ID (position or name)' if not defined $ID or not $ID;
    my $entry = $self->_get_entry( $ID, $list );
    return $entry unless ref $entry;
    $self->{'list'}{'named'}->remove_entry( $entry );
    delete $self->{'entry_by_name'}{ $entry->name };
    $new_name //= '';
    $entry->rename( $new_name );
    return unless $new_name;
    $self->{'list'}{'named'}->insert_entry( $entry, $self->{'config'}{'list'}{'default_insert_position'} );
    $self->{'entry_by_name'}{ $new_name } = $entry;
}

sub copy_entry {
    my ($self, $list_origin, $ID_origin, $list_target, $ID_target) = @_;
    return 'missing source entry ID (position or name)' if not defined $ID_origin or not $ID_origin;
    my $entry = $self->_get_entry( $ID_origin, $list_origin );
    return $entry unless ref $entry;
    return "can not copy deleted entrie" if $entry->is_in_list('bin');

    my $list = $self->get_list_or_current($list_target);
    return "unknonw target list" unless ref $list;
    return 'can not copy into special list' if $self->is_list_special( $list->name );
    my $pos = $list->get_entry_by_property( 'name', $ID_target ) // $list->get_entry_by_pos( $ID_target );

    $pos = (ref $pos) ? $pos->list_pos->get( $list->name ) : $self->{'config'}{'list'}{'default_insert_position'};
    $list->insert_entry( $entry, $pos);
}


sub move_entry {
    my ($self, $list_origin, $ID_origin, $list_target, $ID_target) = @_;
    return 'missing source entry ID (position or name)' if not defined $ID_origin or not $ID_origin;
    my $entry = $self->_get_entry( $ID_origin, $list_origin );
    return $entry unless ref $entry;

    my $i_list = $self->get_list_or_current($list_origin);
    my $o_list = $self->get_list_or_current($list_origin);
    return "unknonw source list" unless ref $i_list;
    return "unknonw target list" unless ref $o_list;
    return 'can not move entry into or out a special list'
        if ($self->is_list_special( $i_list->name ) or $self->is_list_special( $o_list->name ))
        and $i_list->name ne $o_list->name;

    $i_list->remove_entry( $entry );
    my $pos = $o_list->get_entry_by_property( 'name', $ID_target ) // $o_list->get_entry_by_pos( $ID_target );

    $pos = (ref $pos) ? $pos->list_pos->get( $o_list->name ) : $self->{'config'}{'list'}{'default_insert_position'};
    $o_list->insert_entry( $entry, $pos);
}

sub remove_entry {
    my ($self, $list, $ID) = @_;
    my $entry = $self->_get_entry( $ID, $list );
    return $entry unless ref $entry;
    $list = $self->get_list_or_current( $list );
    return 'unknown list name' unless ref $list;
    return 'can not remove from special list' if $self->is_list_special( $list->name );
    $list->remove_entry( $entry );
}

sub delete_entry {
    my ($self, $list, $ID) = @_;
    my $entry = $self->_get_entry( $ID, $list );
    return $entry unless ref $entry;
    my $bin = $self->{'list'}{'bin'};
    return 'this entry is already deleted' if $bin->has_entry( $entry );

    $list = $self->get_list_or_current( $list );
    return 'unknown list name' unless ref $list;
    my $entry = ($ID =~ /^d+$/)
              ? $list->get_entry_by_pos( $ID )
              : $list->get_entry_by_property( 'name', $ID );
    return 'unknown ID target (position or name) in list '.$list->name unless ref $entry;
    return 'this entry is already deleted' if $bin->has_entry( $entry );
    for my $list (values %{$self->{'list'}}){
        next if $list->name eq 'all' or $list->name eq 'bin';
        $list->remove_entry( $entry );
    }
    $entry->delete();
    $bin->insert_entry( $entry, -1 );
}

sub undelete_entry {
    my ($self, $origin, $list, $target) = @_;
    return "missing ID (position or name) of entry to undelete: $origin" if not defined $origin or not $origin;
    my $bin = $self->{'list'}{'bin'};
    my $entry = ($origin =~ /^d+$/)
              ? $bin->get_entry_by_pos( $origin )
              : $bin->get_entry_by_property( 'name', $origin );
    return 'unknown ID target (position or name) in list '.$list->name unless ref $entry;
    $entry->delete();
    return 'this entry is already deleted' if $bin->has_entry( $entry );
    for my $list (values %{$self->{'list'}}){
        next if $list->name eq 'all' or $list->name eq 'bin';
        $list->remove_entry( $entry );
    }
    $entry->undelete();
    #$bin->insert_entry( $entry, -1 );
}

########################################################################
sub undo         {
    my ($self) = @_;
}

sub redo         {
    my ($self) = @_;
}
##### helper ###########################################################
sub _pos_for_list {
    my ($self, $wanted_list, $got_list, $pos) = @_;
    return $self->{'config'}{'list'}{'default_insert_position'} unless
        defined $wanted_list and defined $got_list and defined $pos and $pos;
    $wanted_list eq $got_list ? $pos : $self->{'config'}{'list'}{'default_insert_position'};
}

sub _get_entry {
    my ($self, $ID, $list) = @_;
    return 'missing entry ID (position or name)' if not defined $ID or not $ID;
    if ($ID =~ /^d+$/){
        my $list_obj = $self->get_list_or_current();
        return 'unknown list name' unless ref $list_obj;
        $list_obj->get_entry_by_pos( $ID );
    }
    else {  $self->entry_by_name( $ID ) // 'unknown entry name' }
}
########################################################################

1;
