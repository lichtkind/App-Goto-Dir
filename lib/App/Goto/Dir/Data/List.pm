
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;   # index: 1 .. count
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::Filter;

my $entry_class = 'App::Goto::Dir::Data::Entry';
my $filter_class = 'App::Goto::Dir::Data::Filter';

#### constructor, object life cycle ############################################
sub new { #           ~name ~decription, @.entry, @.filter -- ~order --> .list
    my ($pkg, $name, $description, $entries, $filter, $order) = @_;
    return 'need 4 arguments: name, description, list entries and list of filter, ordering name is optional'
         if ref $entries ne 'ARRAY' or ref $filter ne 'ARRAY' or not $name or not $description;

    my @entries = grep { _is_entry( $_ ) } @$entries;
    my @filter = grep { _is_filter( $_ ) } @$filter;
    my $self = bless { name => $name, description => $description,
                       entry => \@entries, filter => \@filter, sorting_order => 'position' };
    $self->_refresh_list_pos;
    $self->set_sorting_order( $order );
    $self;
}

sub restate {
    my ($pkg, $state, $entries, $filter) = @_;
    App::Goto::Dir::Data::List->new( $state->{'name'}, $state->{'description'},
                                     $entries, $filter, $state->{'order'}      );
}
sub state   { return { name => $_[0]->{'name'}, description => $_[0]->{'description'}, order => $_[0]->{'order'} }}
sub destroy {
    my ($self) = @_;
    $_->list_pos->remove_list( $self->name ) for $self->all_entries;
    return 1;                      # object can be discarded by holder if return is positive
}

#### list accessors ############################################################
sub name              { $_[0]->{'name'} }
sub rename            {
    my ($self, $new_name) = @_;
    my $old_name = $self->name;
    return unless defined $new_name and $new_name and $new_name ne $old_name;
    $_->add_set( $new_name, $_->remove_set( $old_name ) ) for $self->all_entries, $self->all_filter;
    $self->{'name'} = $new_name;
}
sub description       { $_[0]->{'description'} }
sub redescribe        { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
sub sorting_order     { $_[0]->{'sorting_order'} }
sub set_sorting_order {
    my ($self, $order, $reverse) = @_;
    return unless defined $order and $order;
    $order = $reverse = substr($order, 8) if substr($order, 0, 8) eq 'reverse ';
    $order = lc $order;
    return unless $order eq 'position' or App::Goto::Dir::Data::Entry::is_property($order);
    $order = 'reverse '.$order if defined $reverse and $reverse;
    $self->{'sorting_order'} = $order;
}
sub reverse_sorting_order {
    my ($self) = @_;
    $self->{'sorting_order'} = (substr($self->{'sorting_order'}, 0, 8) eq 'reverse ')
                             ? substr($self->{'sorting_order'}, 8)
                             : 'reverse '.$self->{'sorting_order'};
}

#### entry API #################################################################
sub all_entries     { @{$_[0]->{'entry'}} } #                        --> @.entry
sub entry_count     { int @{$_[0]->{'entry'}} } #                    --> +
sub has_entry       { (is_entry( $_[1]) and $_[1]->is_in_list( $_[0]->name )) ? 1 : 0 }

sub is_position     { #                           +pos -- +add_range --> ?
    my ($self, $pos, $add_range) = @_;
    $self->resolve_position( $pos, $add_range ) ? 1 : 0;
}
sub nearest_position { #                          +pos -- +add_range --> +pos
    my ($self, $pos, $add_range) = @_; # third arg lets sub assume count
    my $max = $self->entry_count + ( $add_range // 0);
    return 0 unless $max;
    return 1 unless defined $pos and $pos;
    $pos = $max + 1 - $pos if $pos < 0;
    return ($pos > $max) ? $max : $pos;
}
sub get_entry_from_position { #                                 +pos --> |.entry
    my ($self, $pos) = @_;
    $pos = $self->_resolve_position( $pos );
    $pos ? $self->{'entry'}[ $pos - 1 ] : undef;
}

sub insert_entry { #                                  .entry -- +pos --> ?.entry
    my ($self, $entry, $pos) = @_;
    return unless is_entry( $entry );
    return if $self->has_entry( $entry );
    $pos = $self->nearest_position( $pos // -1, 1 );
    $entry->list_pos->add_set( $self->name );
    splice @{$self->{'entry'}}, $pos-1, 0, $entry;
    $self->_refresh_list_pos( );
    $entry;
}
sub remove_entry { #                                     .entry|+pos --> ?.entry
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

#### apply filter and sorting ##########################################
sub processed_entries { #                                            --> @.entry
    my ($self) = @_;
    my @entries = $self->all_entries;
    my $order = $self->{'sorting_order'};
    my $reverse = 0;
    if (substr($order, 0, 8) eq 'reverse ') {
        $reverse = 1;
        $order = substr( $order, 8 );
    }
    if ($self->{'sorting_order'} ne 'position') {
        my $property = $self->{'sorting_order'};
        @entries = sort { $a->cmp_property($property, $b) } @entries;
    }
    @entries = reverse @entries if $reverse;
    for my $filter ( $self->all_filter ) {
        my $mode = $filter->list_modes->get_in( $self->name );
        if    ($mode eq 'o') { @entries = grep {$filter->accept_entry($_) } @entries }
        elsif ($mode eq 'x') { @entries = grep {!$filter->accept_entry($_) } @entries }
    }
    return @entries;
}

sub report {
    my ($self) = @_;
    my @entries = $self->processed_entries;
    my $report = ' - entries of list '.$self->name." :\n";

    my $pos = 1;
    for my $entry (@entries) {
        $report .= sprintf "  [%02u]  %6s  %s\n", $pos++, $entry->name, $entry->dir;
    }
    $report
}

#### filter API #################################################################
sub all_filter { @{$_[0]->{'filter'}} }       #                      --> @.filter

##### helper ###########################################################
sub _is_entry  { (ref $_[0] eq $entry_class) ? 1 : 0 }
sub _is_filter { (ref $_[0] eq $filter_class) ? 1 : 0 }
sub _refresh_list_pos {
    my ($self) = @_;
    $self->{'entry'}[$_-1]->list_pos->set_in( $self->name, $_ ) for 1 .. $self->entry_count;
}
sub _resolve_position     {
    my ($self, $pos, $add_range) = @_;
    return 0 unless defined $pos and $pos and (int($pos) == $pos+0 );
    my $max = $self->entry_count + ( $add_range // 0);
    return 0 unless $pos <= $max and $pos >= (- $max);
    $pos > 0 ? $pos : ( $max + 1 - $pos);
}

#### end ###############################################################

1;

__END__
sub processed_entries{}    #                      --> @.entry           # filtered and ordered
sub report           {}    #                      --> ~report

sub all_filter       {}    #                      --> @.filter
sub add_filter       {}    #  .filter,      ~mode --> ?.filter
sub remove_filter    {}    #  ~filter_name        --> ?.filter
sub get_filter_mode  {}    #  ~filter_name        --> ?~mode            # := - inactive
sub set_filter_mode  {}    #  ~filter_name, ~mode --> ?~mode            #    x eXclude
                                                                        #    o pass (OK)
                                                                        #    m mark                                                                      #    m mark
sub get_entry_from_property {
    my ($self, $property, $value) = @_;
    return $self->get_entry_by_pos($value) if defined $property and $property eq 'pos' and defined $value;
    return unless App::Goto::Dir::Data::Entry::is_property( $property ) and defined $value;
    my @entries;
    for my $entry ($self->all_entries){
        push @entries, $entry if $entry->property_equals($property, $value);
    }
    @entries == 1 ? $entries[0] : @entries;
}

