use v5.18;
use warnings;

use App::Goto::Dir::Data::List;

package App::Goto::Dir::Data;

my @special_list_name = qw/new bin all recent/;
my @special_entry_name = qw/last previous add del name/

#### de- constructors ##################################################

sub new {
    my ($pkg) = @_;
    bless { list => {}, all_entry => [], entry_by_name => {}, special_entry => {} };
}

sub restate {
    my ($pkg, $state);
    return unless ref $state eq 'HASH' and ref $state->{'list'} eq 'HASH' and ref $state->{'entry'} eq 'ARRAY';
}

sub state {
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

#### entry API #########################################################

sub get_entry_by_pos {
    my ($self, $pos, $list) = @_;
    $entry;
}

sub get_entry_by_name {
    my ($self, $pos, $list) = @_;
    $entry;
}
sub special_entry       { $_[0]->visit_entry( $_[0]->get_special_entry('last'),  $_[0]->{'visits'}{'last_subdir'} ) }


sub new_entry {
    my ($self, $dir, $name, $list) = @_;
    return unless exists $self->{'special_entry'}{$name};
    wantarray ? @{$self->{'special_entry'}{$name}} : $self->{'special_entry'}{$name}->[0];
}
sub move_entry {
    my ($self, $dir, $name, $list) = @_;
    return unless exists $self->{'special_entry'}{$name};
    wantarray ? @{$self->{'special_entry'}{$name}} : $self->{'special_entry'}{$name}->[0];
}
sub copy_entry {
    my ($self, $dir, $name, $list) = @_;
    return unless exists $self->{'special_entry'}{$name};
    wantarray ? @{$self->{'special_entry'}{$name}} : $self->{'special_entry'}{$name}->[0];
}
sub delete_entry {
    my ($self, $dir, $name, $list) = @_;
    return unless exists $self->{'special_entry'}{$name};
    wantarray ? @{$self->{'special_entry'}{$name}} : $self->{'special_entry'}{$name}->[0];
}

########################################################################
sub undo         { my ($self) = @_; } # TODO
sub redo         { my ($self) = @_; }

1;
