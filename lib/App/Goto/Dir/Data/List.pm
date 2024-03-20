use v5.18;
use warnings;

use App::Goto::Dir::Data::Entry;

package App::Goto::Dir::Data::List;   # index: 1 .. count

#### constructor #######################################################
sub new {
    my ($pkg, $name, $description, $special, $entries) = @_;
    return unless ref $entries eq 'ARRAY' and defined $name;
    my @e = sort { $a->list_pos->get($name) <=> $b->list_pos->get($name) }
            grep { $_->list_pos->get($name)}
            grep { is_entry( undef, $_ )  } @$entries;

    my $self = bless { name => $name, description => $description // '',
                       special => $special // 0, entry => \@e };
    $self->_refresh_list_pos;
    $self;
}

#### accessors #########################################################
sub name            { $_[0]->{'name'} }
sub set_name        { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] }
sub description     { $_[0]->{'description'} }
sub set_description { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
sub is_special      { $_[0]->{'special'} ? 1 : 0}

#### entry API #########################################################
sub is_entry        { (ref $_[1] eq 'App::Goto::Dir::Data::Entry') ? 1 : 0 }
sub has_entry       { ($_[0]->is_entry( $_[1] ) and $_[1]->list_pos->is_member_of( $_[0]->name )) ? 1 : 0 }
sub all_entries     { @{$_[0]->{'entry'}} }
sub entry_count     { int @{$_[0]->{'entry'}} }
sub is_position     {
    my ($self, $pos) = @_;
    $pos = $self->resolve_position( $pos );
    (defined $pos and exists $self->{'entry'}[$pos]) ? 1 : 0;
}
sub resolve_position     {
    my ($self, $pos) = @_;
    return undef unless defined $pos and $pos;
    $pos > 0 ? (int($pos) - 1) : int($pos);
}
sub nearest_position {
    my ($self, $pos, $add_max) = @_; # third arg lets sub assume count += add_max
    my $count = $self->entry_count + ( $add_max // 0);
    (not defined $pos or $pos > $count) ? $count    :
      ($pos < -$count or abs($pos) < 1) ? 1         :
      $pos > 0                          ? int($pos) : ( $count + 1 + int($pos) );
}

sub get_entry_by_pos {
    my $pos = $_[0]->resolve_position($_[1]);
    (defined $pos and exists $_[0]->{'entry'}[ $pos ]) ? $_[0]->{'entry'}[ $pos ] : undef;
}
sub get_entry_by_property {
    my ($self, $property, $value) = @_;
    return $self->get_entry_by_pos($value) if defined $property and $property eq 'pos' and defined $value;
    return unless App::Goto::Dir::Data::Entry::is_property( $property ) and defined $value;
    my @entries;
    for my $entry ($self->all_entries){
        push @entries, $entry if $entry->property_equals($property, $value);
    }
    @entries == 1 ? $entries[0] : @entries;
}

sub insert_entry {
    my ($self, $entry, $pos) = @_;
    return unless $self->is_entry( $entry);
    return if $entry->list_pos->is_member_of( $self->name );
    $pos = $self->nearest_position( $pos // -1, 1 );
    $entry->list_pos->add_list( $self->name );
    splice @{$self->{'entry'}}, $pos-1, 0, $entry;
    $self->_refresh_list_pos( );
    $entry;
}
sub remove_entry {
    my ($self, $ID) = @_;
    if ($self->is_entry( $ID )) {
        return unless $self->has_entry( $ID );
        $ID = $ID->list_pos->get( $self->name );
    }
    return undef unless $self->is_position( $ID );
    my $pos = $self->resolve_position( $ID );
    my $entry = splice @{$self->{'entry'}}, $pos, 1;
    return unless $self->is_entry( $entry );
    $entry->list_pos->remove_list( $self->name );
    $self->_refresh_list_pos( );
    $entry;
}

sub empty_list {
    my ($self) = @_;
    $self->{'entry'}[$_-1]->list_pos->remove_list( $self->name ) for 1 .. $self->entry_count;
    my $c = $self->entry_count;
    $self->{'entry'} = [];
    $c;
}

sub report {
    my ($self, $sort_order, $reverse, $columns) = @_;
    my $report = ' - entries of list '.$self->name." :\n";
    my @order = 1 .. $self->entry_count;
    if ( App::Goto::Dir::Data::Entry::is_property( $sort_order ) ){
        if ( App::Goto::Dir::Data::Entry::is_numeric_property( $sort_order) ){
            @order = sort {$self->{'entry'}[$a-1] <=> $self->{'entry'}[$b-1]} @order;
        } else {
            @order = sort {$self->{'entry'}[$a-1] cmp $self->{'entry'}[$b-1]} @order;
        }
    }
    @order = reverse @order if defined $reverse and $reverse;
    for my $i (@order){
        my $entry = $self->{'entry'}[$i-1];
        $report .= sprintf "  [%02u]  %6s  %s\n", $i, $entry->name, $entry->dir;
    }
    $report
}

##### helper ###########################################################
sub _refresh_list_pos {
    my ($self) = @_;
    $self->{'entry'}[$_-1]->list_pos->set( $self->name, $_ ) for 1 .. $self->entry_count;
}
#### end ###############################################################

1;
