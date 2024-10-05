use v5.18;
use warnings;
use App::Goto::Dir::Data::Entry;

package App::Goto::Dir::Data::Filter;   # index: 1 .. count

#### constructor, object life cycle ############################################
sub new {
    my ($pkg, $name, $description, $code) = @_;
    return unless defined $code and $name and $description and $code;
# check is_property
# check eval
    $code = 'sub { my $el = shift; return if ref $el ne "App::Goto::Dir::Data::Entry";'.$code.'}';
    my $ref = eval $code;
    return "bad code for Filter: $@" if $@;
    # smoke tst with ref
    bless { name => $name, description => $description, code => $code, ref => $ref};
}
sub restate {
    my %self = %{$_[0]};
    $self->{ref} = eval $self->{code};
    bless $self;
}
sub state   { return {name => $_[0]->{'name'}, description => $_[0]->{'description'}, code => $_[0]->{'code'}, } }

#### list accessors ############################################################
sub name            { $_[0]->{'name'} }
sub rename          { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] }
sub description     { $_[0]->{'description'} }
sub set_description { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }

#### entry API #################################################################
sub accept_entry    {
    my ($self, $entry) = @_;
    return if ref ne 'App::Goto::Dir::Data::Entry';
}

sub report {
    my ($self, $width) = @_;
    $width //= 80;
    return substr( $self->{'name'}.': '.$self->{'description'}, 0, $width);
}
#### end ###############################################################

1;
