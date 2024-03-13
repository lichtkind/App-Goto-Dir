use v5.18;
use warnings;

package App::Goto::Dir::Data::ValueType::Position;

#### de- constructors ##################################################

sub new     {
    my ($pkg) = @_;
    bless { };
}

sub restate {
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH';
    bless { %$state };
}
sub state   { return { %{$_[0]} } }
sub clone   { $_[0]->restate( $_[0]->state ) }

#### getter/setter #####################################################

sub get_position {
    my ($self, $list_name) = @_;
    $self->is_member_of($list_name) ? $self->{$list_name} : 0;
}
sub set_position {
    my ($self, $list_name, $pos) = @_;
    return unless $self->is_member_of( $list_name ) and defined $pos and $pos;
    $self->{$list_name} = int $pos;
}

sub add_list {
    my ($self, $list_name, $pos) = @_;
    return if $self->is_member_of( $list_name );
    $self->{$list_name} = int ($pos // 0);
}
sub remove_list {
    my ($self, $list_name) = @_;
    return unless $self->is_member_of( $list_name );
    delete $self->{$list_name};
}

#### predicates ########################################################

sub is_member_of { (defined $_[1] and exists $_[0]->{ $_[1] }) ? 1 : 0 }

sub list_names {
    my $self = shift;
    keys %$self
}

#### display ###########################################################

sub format {
    my $self = shift;    #
}

#### utils #############################################################
#### end ###############################################################

1;

