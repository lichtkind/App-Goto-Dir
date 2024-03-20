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
    my $self = { list => {}, entry_by_name => {}, special_entry => {}, current_list => 'all', command_stack => [] };
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new($_, $special_list{$_}, 1, []) for keys %special_list;
    $self->{'special_entry'}{$_} = '' for keys %special_entry;
    bless $self;
}

sub restate {
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'list'} eq 'HASH' and exists $state->{'current_list'};
    my $self = {list => {}, entry_by_name => {}, special_entry => {}, current_list => '', command_stack => []};
    $self->{'current_list'} = $state->{'current_list'};
    my @entries = map { App::Goto::Dir::Data::Entry->restate($_) } @{$state->{'entry'}};
    map { $self->{'entry_by_name'}{$_->name} = $_ if $_->name } @entries;
    $self->{'list'}{$_} = App::Goto::Dir::Data::List->new (
                              $_, $state->{'list'}{$_}, ((exists $special_list{$_}) ? 1 : 0), \@entries,
                                                          ) for keys %{$state->{'list'}};
    $self->{'special_entry'}{$_} = $state->{'special_entry'}{$_}
                                  ? $self->{'list'}{'all'}->get_entry_by_property( 'dir', $state->{'special_entry'}{$_} )
                                  : ''                      for keys %special_entry;
    bless $self;
}

sub state {
    my ($self, $state) = (shift, {entry => []});
    $state->{'current_list'} = $self->{'current_list'};
    $state->{'list'}{$_} = $self->{'list'}{$_}->description for keys %{$self->{'list'}};
    push @{$state->{'entry'}}, $_->state for $self->all_entries;
    $state->{'special_entry'}{$_} = (ref $self->{'special_entry'}{$_})
                                  ? $self->{'special_entry'}{$_}->dir
                                  : ''                                for keys %special_entry;
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
sub all_entries { $_[0]->get_list('all')->all_entries }

sub get_entry_by_pos {
    my ($self, $pos, $list) = @_;
    #$entry;
}

sub get_entry_by_name {
    my ($self, $pos, $list) = @_;
    #$entry;
}
sub special_entry {
    my ($self, $name) = @_;

}


sub new_entry {
    my ($self, $dir, $name, $pos, $list) = @_;
}
sub copy_entry {
    my ($self, $ID_origin, $list_origin, $ID_target, $list_target) = @_;
}
sub move_entry {
    my ($self, $ID_origin, $list_origin, $ID_target, $list_target) = @_;
}
sub remove_entry {
    my ($self, $ID, $list) = @_;
}
sub delete_entry {
    my ($self, $ID, $list) = @_;
}

########################################################################
sub undo         { my ($self) = @_; } # TODO
sub redo         { my ($self) = @_; }

1;
