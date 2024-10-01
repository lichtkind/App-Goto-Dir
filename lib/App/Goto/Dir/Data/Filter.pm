use v5.18;
use warnings;
use App::Goto::Dir::Data::Entry;

package App::Goto::Dir::Data::Filter;   # index: 1 .. count

#### constructor, object life cycle ############################################
sub new {
    my ($pkg, $name, $description, $special) = @_;
    return unless defined $name and $name;

    my $self = bless { name => $name, description => $description // '',
                       special => $special // 0,};
    $self->_refresh_list_pos;
    $self;
}

sub restate {
    my ($state, $entries) = @_;
    App::Goto::Dir::Data::List->new( $state->{'name'}, $state->{'description'}, $state->{'special'}, $entries);
}
sub state   {
    return {name => $_[0]->{'name'}, description => $_[0]->{'description'}, special => $_[0]->{'special'}, };
}
sub destroy {
    my ($self) = @_;
    return 0 if $self->is_special; # user can not remove special lists
    $_->list_pos->remove_list( $self->name ) for $self->all_entries;
    return 1;                      # object can be discarded by holder
}

#### list accessors ############################################################
sub name            { $_[0]->{'name'} }
sub rename          {
    my ($self, $new_name) = @_;
    my $old_name = $self->name;
    return unless defined $new_name and $new_name and $new_name ne $old_name;
    if ($self->entry_count > 0) {
        $_->list_pos->add_list( $new_name, $_->list_pos->remove_list( $old_name ) )
            for $self->all_entries;
    }
    $self->{'name'} = $new_name;
}
sub description     { $_[0]->{'description'} }
sub set_description { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
sub is_special      { $_[0]->{'special'} ? 1 : 0}

#### entry API #################################################################
sub is_entry        { (ref $_[1] eq 'App::Goto::Dir::Data::Entry') ? 1 : 0 }
sub has_entry       { ($_[0]->is_entry( $_[1] ) and $_[1]->is_in_list( $_[0]->name )) ? 1 : 0 }
sub all_entries     { @{$_[0]->{'entry'}} }
sub entry_count     { int @{$_[0]->{'entry'}} }

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

#### entry position API ########################################################
sub get_entry_by_pos {
    my ($self, $pos) = @_;
    $pos = $self->resolve_position( $pos );
    $pos ? $self->{'entry'}[ $pos - 1 ] : undef;
}

sub resolve_position     {
    my ($self, $pos, $add_range) = @_;
    return 0 unless defined $pos and $pos and (int($pos) == $pos+0 );
    my $max = $self->entry_count + ( $add_range // 0);
    return 0 unless $pos <= $max and $pos >= (- $max);
    $pos > 0 ? $pos : ( $max + 1 - $pos);
}
sub is_position     {
    my ($self, $pos, $add_range) = @_;
    $self->resolve_position( $pos, $add_range ) ? 1 : 0;
}

sub nearest_position {
    my ($self, $pos, $add_range) = @_; # third arg lets sub assume count
    my $max = $self->entry_count + ( $add_range // 0);
    return 0 unless $max;
    return 1 unless defined $pos and $pos;
    $pos = $max + 1 - $pos if $pos < 0;
    return ($pos > $max) ? $max : $pos;
}
sub _refresh_list_pos {
    my ($self) = @_;
    $self->{'entry'}[$_-1]->list_pos->set( $self->name, $_ ) for 1 .. $self->entry_count;
}

#### entry position API ########################################################
sub insert_entry {
    my ($self, $entry, $pos) = @_;
    return unless $self->is_entry( $entry);
    return if $entry->is_in_list( $self->name );
    $pos = $self->nearest_position( $pos // -1, 1 );
    $entry->list_pos->add_list( $self->name );
    splice @{$self->{'entry'}}, $pos-1, 0, $entry;
    $self->_refresh_list_pos( );
    $entry;
}

sub remove_entry {
    my ($self, $ID) = @_; # ID = pos or entry objecty
    if ($self->is_entry( $ID )) {
        return unless $self->has_entry( $ID );
        $ID = $ID->list_pos->get( $self->name );
    }
    return unless $self->is_position( $ID );
    my $pos = $self->resolve_position( $ID );
    my $entry = splice @{$self->{'entry'}}, $pos-1, 1;
    return unless $self->is_entry( $entry );
    $entry->list_pos->remove_list( $self->name );
    $self->_refresh_list_pos( );
    $entry;
}

### output #####################################################################
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

#### end ###############################################################

1;
