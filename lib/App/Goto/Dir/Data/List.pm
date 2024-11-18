
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;   # index: 1 .. count
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::Filter;

my $entry_class = 'App::Goto::Dir::Data::Entry';
my $filter_class = 'App::Goto::Dir::Data::Filter';

#### constructor, object life cycle ############################################
sub new { #                     ~name ~decription, @.entry, @.filter -- ~order --> .list
    my ($pkg, $name, $description, $entries, $filter, $order) = @_;
    return 'need 4 arguments: name, description, list entries and list of filter, ordering name is optional'
         if ref $entries ne 'ARRAY' or ref $filter ne 'ARRAY' or not $name or not $description;

    my @entries = grep { _is_entry( $_ ) } @$entries;
    my @filter = grep { _is_filter( $_ ) } @$filter;
    my $self = bless { name => $name, description => $description,
                       entry => \@entries, filter => \@filter, sorting_order => $order // 'position' };
    $self->_refresh_list_pos;
    $self;
}

sub restate {
    my ($pkg, $state, $entries, $filter) = @_;
    App::Goto::Dir::Data::List->new( $state->{'name'}, $state->{'description'},
                                     $entries, $filter, $state->{'order'} );
}
sub state   { return { name => $_[0]->{'name'}, description => $_[0]->{'description'},
                       order => $_[0]->{'order'}                                       }}
sub destroy {
    my ($self) = @_;
    $_->list_pos->remove_list( $self->name ) for $self->all_entries;
    return 1;                      # object can be discarded by holder if positive
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
sub set_sorting_order { $_[0]->{'sorting_order'} = $_[1] if defined $_[1] and $_[1]
                            and ($_[1] eq 'position' or App::Goto::Dir::Data::Entry::is_property($_[1])) }

#### entry API #################################################################
sub all_entries     { @{$_[0]->{'entry'}} }
sub entry_count     { int @{$_[0]->{'entry'}} }
sub has_entry       { (is_entry( $_[1]) and $_[1]->is_in_list( $_[0]->name )) ? 1 : 0 }
sub get_entry_by_pos{
    my ($self, $pos) = @_;
    $pos = $self->_resolve_position( $pos );
    $pos ? $self->{'entry'}[ $pos - 1 ] : undef;
}

#### entry position API ########################################################

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

sub all_entries      {}    #                      --> @.entry
sub entry_count      {}    #                      --> +
sub is_position      {}    #                 +pos --> ?
sub nearest_position {}    #                 +pos --> +pos
sub has_entry        {}    #               .entry --> ?
sub get_entry_by_pos {}    #                 +pos --> ?.entry
sub add_entry        {}    #       .entry -- +pos --> ?.entry
sub remove_entry     {}    #                 +pos --> ?.entry

sub get_order        {}    #                      --> ~order
sub set_order        {}    # ~order               --> ?~order
sub processed_entries{}    #                      --> @.entry           # filtered and ordered
sub report           {}    #                      --> ~report

sub all_filter       {}    #                      --> @.filter
sub add_filter       {}    #  .filter,      ~mode --> ?.filter
sub remove_filter    {}    #  ~filter_name        --> ?.filter
sub get_filter_mode  {}    #  ~filter_name        --> ?~mode            # := - inactive
sub set_filter_mode  {}    #  ~filter_name, ~mode --> ?~mode            #    x eXclude
                                                                        #    o pass (OK)
                                                                        #    m mark                                                                      #    m mark
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

