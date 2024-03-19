use v5.18;
use warnings;

use App::Goto::Dir::Data::List;

package App::Goto::Dir::Data;

my @special_list_name = qw/new bin all used/;
my @special_entry_name = qw/last prev add del name move/

#### de- constructors ##################################################

sub new {
    my ($pkg) = @_;
    bless { list => {}, entry_by_name => {}, special_entry => {}, current_list => '', command_stack => [] };
}

sub restate {
    my ($pkg, $state);
    return unless ref $state eq 'HASH' and ref $state->{'list'} eq 'HASH' and ref $state->{'entry'} eq 'ARRAY';
}

sub state {
    my ($self, $state) = shift;

    $state;
}


#### list API ###########################################################
sub new_list {
    my ($self, $list_name, $description, $config, @elems) = @_;
    $self->{'list_object'}{ $list_name } = App::Goto::Dir::Data::List->new( $list_name, $description, $config, @elems );
}
sub remove_list           { delete $_[0]->{'list_object'}{ $_[1] }                    }
sub get_list              { $_[0]->{'list_object'}{$_[1]} if exists $_[0]->{'list_object'}{$_[1]} }
sub list_exists           { defined $_[1] and exists $_[0]->{'list_object'}{$_[1]}    }
sub change_current_list   { $_[0]->{'list'}{'current'} = $_[1] if exists $_[0]->{'list_object'}{$_[1]} }
sub get_current_list      { $_[0]->{'list_object'}{ $_[0]->{'list'}{'current'} }      }
sub get_all_lists         { keys %{$_[0]->{'list_object'}}                            }
sub get_special_lists     { my $self = shift; @{ $self->{'list_object'}}{ $self->get_special_list_names(@_) } if @_}
sub get_normal_lists      { my $self = shift; @{ $self->{'list_object'}}{ $self->get_special_list_names(@_) } if @_}
sub report      {
    my ($self, $report) = shift;

    $report;
}

#### entry API #########################################################

sub get_entry_by_pos {
    my ($self, $pos, $list) = @_;
    $entry;
}

sub get_entry_by_name {
    my ($self, $pos, $list) = @_;
    $entry;
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
