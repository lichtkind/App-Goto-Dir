use v5.18;
use warnings;

use App::Goto::Dir::Data::List;

package App::Goto::Dir::Data;

my %special_list = (new => 'recently created directory entries',
                    bin => 'deleted but not yet discarded entries',
                    all => 'all entries, even the deleted',
                    now => 'recently visited entries',);
my %special_entry = (last => 'entry last visited',
                     prev => 'entry second last visited',
                     add  => 'last entry created',
                     del  => 'last entry deleted',
                     name => 'last entry named',
                     move => 'last entry copied, moved or removed',);
#### de- constructors ##################################################
sub new {
    my ($pkg) = @_;
    my $self = { list => {}, current_list => 'all', entry_by_name => {}, entry_by_dir => {}, special_entry => {},
                 undo_stack => [], redo_stack => [] };
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new($_, $special_list{$_}, 1, []) for keys %special_list;
    $self->{'special_entry'}{$_} = '' for keys %special_entry;
    bless $self;
}

sub restate {
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'list'} eq 'HASH' and exists $state->{'current_list'};
    my $self = { list => {}, current_list => '',
                 entry_by_name => {}, entry_by_dir => {}, special_entry => {},
                 undo_stack => [], redo_stack => [] };
    $self->{'current_list'} = $state->{'current_list'};
    my @entries = map { App::Goto::Dir::Data::Entry->restate($_) } @{$state->{'entry'}};
    map { $self->{'entry_by_name'}{$_->name} = $_ if $_->name } @entries;
    map { $self->{'entry_by_dir'}{$_->name} = $_ if $_->dir } @entries;
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new (
                              $_, $state->{'list'}{$_}, ((exists $special_list{$_}) ? 1 : 0), \@entries,
                                                          ) for keys %{$state->{'list'}};
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

#### list API ###########################################################
sub new_list {
    my ($self, $list_name, $description, @elems) = @_;
    return 'need a list name' unless defined $list_name and $list_name;
    return 'list already exists' if exists $self->{'list'}{ $list_name };
    $self->{'list'}{ $list_name } = App::Goto::Dir::Data::List->new( $list_name, $description, 0, [@elems] );
}
sub list_exists  { (defined $_[1] and exists $_[0]->{'list'}{$_[1]}) ? 1 : 0 }
sub get_list     { $_[0]->{'list'}{$_[1]} if list_exists($_[1]) }
sub get_list_or_current { $_[0]->get_list($_[1]) // $_[0]->get_current_list}

sub remove_list  {
    my ($self, $list_name) = @_;
    return if not exists $self->{'list'}{ $list_name } or $self->{'list'}{ $list_name }->is_special;
    $self->{'list'}{ $list_name }->empty_list;
    delete $self->{'list'}{ $list_name };
}

sub set_current_list      { $_[0]->{'current_list'} = $_[1] if $_[0]->list_exists( $_[1] ) }
sub get_current_list      { $_[0]->{'list'}{ $_[0]->{'current_list'} }   }
sub report      {
    my $self = shift;
    my $report = " - listing of all lists :\n";
    my @order = sort { $self->{'list'}[$a-1]->name cmp $self->{'list'}[$b-1]->name }
                     1 .. int @{$_[0]->{'list'}};

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
sub entry_by_dir     { $_[0]->{'entry_by_dir'} { $_[1] } } # by normalized directory
sub entry_by_name    { $_[0]->{'entry_by_name'}{ $_[1] } }
sub special_entry    { $_[0]->{'special_entry'}{ $_[1] } }
sub get_entry_by_pos {
    my ($self, $list, $pos) = @_;
    $list = $self->get_list_or_current( $list );
    $list->get_entry_by_pos( $pos ) if ref $list;
}

sub new_entry {
    my ($self, $dir, $name, $list, $pos) = @_;
    my $all = $self->{'list'}{'all'};
    return 'dir is already part of an entry' if ref $self->get_entry_by_property('dir', $dir);
    $name = '' if $self->entry_by_name( $name ); # name was taken
    my $entry = App::Goto::Dir::Data::Entry->new( $dir, $name );
    my $allpos = (defined $list and defined $pos and $list eq 'all') ? $pos : -1;
    my $newpos = (defined $list and defined $pos and $list eq 'new') ? $pos : -1;
    $all->insert_entry($entry, $allpos);
    $self->{'list'}{'new'}->insert_entry($entry, $newpos);
    my $l = $self->get_current_list;
    return $entry if $l->has_entry( $entry );
    $l->insert_entry($entry, $pos // -1);
}

sub copy_entry {
    my ($self, $list_origin, $ID_origin, $list_target, $ID_target) = @_;
    return 'missing source entry ID (position or name)' if not defined $ID_origin or not $ID_origin;
    my $entry;
    if ($ID_origin =~ /^d+$/){
        my $origin = $self->get_list_or_current($list_origin);
        return 'unknown origin list' unless ref $origin;
        $entry = $origin->get_entry_by_pos( $ID_origin );
    } else {
        $entry = $self->entry_by_name( $ID_origin );
    }
    return "unknown source ID (position or name): $ID_origin " unless ref $entry;
    my $target = $self->get_list_or_current($list_target);
    return 'unknown target list' unless ref $target;
    if ($ID_target !~ /^d+$/){
        my $target_entry = $target->get_entry_by_property( 'name', $ID_target);
        return 'list '.$target->name.'does not contain entry with name '.$entry->name unless ref $target_entry;
        $ID_target = $target_entry->list_pos->get( $target->name );
    }
    $target->insert_entry( $entry, $ID_target || -1);
}


sub move_entry {
    my ($self, $list_origin, $ID_origin, $list_target, $ID_target) = @_;
    return 'missing source entry ID (position or name)' if not defined $ID_origin or not $ID_origin;
    my $origin = $self->get_list_or_current($list_origin);
    return 'unknown origin list' unless ref $origin;

    my $entry = ($ID_origin =~ /^d+$/)
              ? $origin->get_entry_by_pos( $ID_origin )
              : $origin->get_entry_by_property( 'name', $ID_origin);
    return "unknown source ID (position or name): '$ID_origin' in list ".$list_origin->name unless ref $entry;

    $origin->remove_entry( $entry );
    my $target = $self->get_list_or_current($list_target);
    return 'unknown target list' unless ref $target;
    my $target_pos = ($ID_target =~ /^d+$/) ? $ID_target
                                            : $target->get_entry_by_property('name', $ID_target);
    $target->insert_entry( $entry, $target_pos || -1);
}

sub remove_entry {
    my ($self, $list, $ID) = @_;
    return "missing entry ID (position or name): $ID" if not defined $ID or not $ID;
    $list = $self->get_list_or_current( $list );
    return 'unknown list name' unless ref $list;

    my $entry = ($ID =~ /^d+$/)
              ? $list->get_entry_by_pos( $ID )
              : $list->get_entry_by_property( 'name', $ID );
    return 'unknown ID target (position or name) in list '.$list->name unless ref $entry;
    $list->remove_entry( $entry );
}

sub delete_entry {
    my ($self, $list, $ID) = @_;
    return "missing entry ID (position or name): $ID" if not defined $ID or not $ID;
    $list = $self->get_list_or_current( $list );
    return 'unknown list name' unless ref $list;
    my $entry = ($ID =~ /^d+$/)
              ? $list->get_entry_by_pos( $ID )
              : $list->get_entry_by_property( 'name', $ID );
    return 'unknown ID target (position or name) in list '.$list->name unless ref $entry;
    my $bin = $self->{'list'}{'bin'};
    return 'this entry is already deleted' if $bin->has_entry( $entry );
    for my $list (values %{$self->{'list'}}){
        next if $list->name eq 'all' or $list->name eq 'bin';
        $list->remove_entry( $entry );
    }
    $bin->insert_entry( $entry, -1 );
}

########################################################################
sub undo         {
    my ($self) = @_;
} # TODO
sub redo         {
    my ($self) = @_;
}

1;
