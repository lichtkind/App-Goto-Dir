use v5.18;
use warnings;

package App::Goto::Dir::Data::ValueType::Relation;

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

#### accessors #########################################################

sub get_in { #     ~list_name   -->   +pos|0
    my ($self, $set_name) = @_;
    $self->is_in_set( $set_name) ? $self->{ $set_name } : 0;
}

sub set_in { #     ~list_name, +pos   -->   +
    my ($self, $set_name, $value) = @_;
    return unless $self->is_in_set( $set_name ) and defined $value and $value;
    $self->{ $set_name } = $value;
}

sub add_set {
    my ($self, $set_name, $value) = @_;
    return if $self->is_in_set( $set_name );
    $self->{ $set_name } = $value;
}
sub remove_set {
    my ($self, $set_name) = @_;
    return unless $self->is_in_set( $set_name );
    delete $self->{ $set_name };
}

sub list_sets {
    my $self = shift;
    keys %$self
}

#### predicates ########################################################

sub is_in_set { (defined $_[1] and exists $_[0]->{ $_[1] }) ? 1 : 0 }

#### end ###############################################################

1;
