use v5.18;
use warnings;

use App::Goto::Dir::Data::Entry;
our $entry_class = 'App::Goto::Dir::Data::Entry';

package App::Goto::Dir::Data::List; # index: 1 .. count

#### constructor #######################################################
sub new {
    my ($pkg, $name, $description, $special) = @_;
    return unless defined $name;
    bless { entry => [], name => $name, description => $description // '',
            pos_by_name => {}, pos_by_dir => {}, special => $special };
}
sub clone   { $_[0]->restate( $_[0]->state ) }
sub restate {
    bless $_[1] if ref $_[1] eq 'HASH'
}
sub state   {
    my ($self) = (shift);
    return { name => $self->{'name'}, description => $self->{'description'}, special => 0}
        unless $self->is_special;
}

#### accessors #########################################################
sub get_name        { $_[0]->{'name'} }
sub set_name        { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] }
sub get_description { $_[0]->{'description'} }
sub set_description { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
sub is_special      { $_[0]->{'special'} }

sub all_entries     { @{$_[0]->{'entry'}} }
sub length          { int @{$_[0]->{'entry'}} }
sub get_entry {
    my ($self, $ID) = @_;
    return "can not get an list entry without ID!" unless defined $ID;
    $ID = $ID->full_dir if ref $ID;
    my $pos = $self->pos_from_ID( $ID );
    return " ! '$ID' is not a valid dir path, name or position in list '".$self->get_name."'" if not $pos;
    wantarray ? ($self->{'entry'}[$pos-1], $pos) : $self->{'entry'}[$pos-1];
}

#### elem API ##########################################################
sub _insert_entry { splice @{$_[0]->{'entry'}}, $_[2]-1, 0, $_[1] }
sub insert_entry {
    my ($self, $entry, $pos) = @_;
    return "need an $elem_class object as argument!" unless ref $entry eq $elem_class;
    $pos = $self->{'config'}{'position_default'} unless defined $pos;
    return "'$pos' is an illegal list position for list $self->{name}" unless $self->is_new_pos($pos);
    $pos += @{$self->{'entry'}} + 2 if $pos < 0; # resolve negative pos
    my $dir_pos = $self->pos_from_dir( $entry->full_dir );
    return 'path '.$entry->full_dir." is already stored in list $self->{name}"
        if $dir_pos and $self->{'config'}{'prefer_in_dir_conflict'} eq 'old';

    if ($entry->name and exists $self->{'pos_by_name'}{ $entry->name } and $self->{'pos_by_name'}{ $entry->name } != $dir_pos){
        if ($self->{'config'}{'prefer_in_name_conflict'} eq 'new')  { $self->{'entry'}[ $self->{'pos_by_name'}{ $entry->name } ]->rename('') }
        else                                                        { $entry->rename('') }
    }
    $self->_insert_entry( $entry, $pos );
    $self->_remove_entry( $dir_pos ) if $dir_pos; # duplikat
    $self->refresh_reverse_hashes();
    $entry;
}

sub _remove_entry { splice @{$_[0]->{'entry'}}, $_[1]-1, 1 }
sub remove_entry {
    my ($self, $ID) = @_;
    return "list $self->{name} needsan entry ref, position or name of element to remove" unless defined $ID;
    my $pos = ref $ID ? $self->pos_from_dir( $ID->full_dir ) : $self->pos_from_ID( $ID );
    return "'".$ID->full_dir."' is not a dir stored in list: $self->{name}" if ref $ID and not $pos;
    return "$ID is not a valid position or name in list $self->{name}" unless $pos;
    my $entry = $self->_remove_entry( $pos );
    $entry->remove_from_list( $self->{'name'} );
    $self->refresh_reverse_hashes();
    $entry;
}

sub move_entry {
    my ($self, $from, $to) = @_;
    my ($entry, $from_pos) = $self->get_entry( $from );
    my $to_pos = $self->pos_from_ID( $to );
    return "'".$from->full_dir."' is not a dir stored in list: $self->{name}" if ref $from and not $from_pos;
    return "'$from' is not a valid dir, name or position of the current list" if not $from_pos;
    return "'$to' is not a valid target name or position of the current list" if not $to_pos;
    $self->_insert_entry( $self->remove_entry( $from_pos ), $to_pos );
    $self->refresh_reverse_hashes();
    $entry;
}

##### helper ###########################################################

sub pos_from_ID {
    my ($self, $ID, $new) = @_;
    return 0 unless defined $ID;
    if (App::Goto::Dir::Parse::is_position( $ID )){
        my $c = int @{$self->{'entry'}};
        $c++ if defined $new and $new;
        $ID += $c + 1 if $ID < 0;
        return $ID if $ID > 0 and $ID <= $c;
    } elsif ( App::Goto::Dir::Parse::is_dir( $ID)) {
        $self->pos_from_dir($ID);
    } else {
        return $self->pos_from_name($ID) if length($ID) <= $self->{'config'}{'name_length_max'};

    }
    0;
}

sub pos_from_name { exists $_[0]->{'pos_by_name'}{ $_[1] } ? $_[0]->{'pos_by_name'}{ $_[1] } : 0 }
sub pos_from_dir  { exists $_[0]->{'pos_by_dir'}{ $_[1] } ? $_[0]->{'pos_by_dir'}{ $_[1] } : 0 }

sub _is_pos     {
    my ($self, $i) = @_;
    my $c = $self->length;
    $i == int $i and (($i > 0 and $i <= $c) or ($i < 0 and $i >= -$c))
}
sub _is_new_pos {
    my ($self, $i) = @_;
    my $c = $self->length;
    $i == int $i and (($i > 0 and $i <= $c+1) or ($i < 0 and $i >= -$c-1))
}

sub _refresh_reverse_hashes {
    my ($self) = @_;
    $self->{'pos_by_name'} = {};
    $self->{'pos_by_dir'} = {};
    for my $pos (1 .. @{$self->{'entry'}}){
        my $el = $self->{'entry'}[$pos-1];
        $el->add_to_list( $self->{'name'}, $pos );
        $self->{'pos_by_dir'}{ $el->full_dir } = $pos;
        $self->{'pos_by_name'}{ $el->name } = $pos if $el->name;
    }
}

#### end ###############################################################

1;
