use v5.18;
use warnings;

use App::Goto::Dir::Data::Entry;

package App::Goto::Dir::Data::List;

my $entry_class = 'App::Goto::Dir::Data::Entry';

#### constructor #######################################################
sub new {
    my ($pkg, $name, $description, $special) = @_;
    return unless defined $name;
    bless { name => $name, description => $description // '', special => $special, entry => []};  # index: 1 .. count
}

#### accessors #########################################################
sub name            { $_[0]->{'name'} }
sub set_name        { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] }
sub description     { $_[0]->{'description'} }
sub set_description { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
sub is_special      { $_[0]->{'special'} ? 1 : 0}

#### entry API #########################################################

sub all_entries     { @{$_[0]->{'entry'}} }
sub entry_count     { int @{$_[0]->{'entry'}} }
sub is_position     {
    my ($self, $pos) = @_;
    my $count = $self->entry_count;
    (defined $pos and (   ($pos >=  1 and $pos <=  $count)
                       or ($pos <= -1 and $pos >= -$count) )) ? 1 : 0;
}
sub nearest_position {
    my ($self, $pos, $add_max) = @_;
    my $count = $self->entry_count + ( $add_max // 0);
    return $count unless defined $pos;
    return 1 if abs($pos) < 1 ;
    return $count if $pos >  $count;
    return 1      if $pos < -$count;
    $pos > 0 ? int($pos) : ($count + 1 + int($pos));
}

sub get_entry_by_pos { $_[0]->{'entry'}[ 1 + $_[0]->nearest_position($_[1]) ] }

sub insert_entry {
    my ($self, $entry, $pos) = @_;
    return unless ref $entry eq $entry_class;
    $pos = $self->nearest_position( $pos, 1 );
    $entry->list_pos->add_list( $self->name );
    splice @{$self->{'entry'}}, $pos-1, 0, $entry;
    $self->_refresh_list_pos( );
    $entry;
}

sub remove_entry {
    my ($self, $pos) = @_;
    $pos = $self->nearest_position( $pos );
    my $entry = splice @{$self->{'entry'}}, $pos-1, 1;
    return unless ref $entry eq $entry_class;
    $entry->list_pos->remove_list( $self->name );
    $self->_refresh_list_pos( );
    $entry;
}

sub report {
    my ($self, $sort_order, $columns) = @_;
    my $report = 'list '.$self->name." :\n";
    for my $i (1 .. $self->entry_count){
        my $entry = $self->{'entry'}[$i-1];
        $report .= sprintf "  [%02u]  %6s  %s\n", $i, $entry->name, $entry->dir;
    }
    $report
}

##### helper ###########################################################

sub _refresh_list_pos {
    my ($self) = @_;
    $self->{'entry'}[$_-1]->list_pos->set_position( $self->name, $_ ) for 1 .. $self->entry_count;
}

#### end ###############################################################

1;
