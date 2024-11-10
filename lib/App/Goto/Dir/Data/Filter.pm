
# entry list filter which may hides entries with defined properties

package App::Goto::Dir::Data::Filter;   # index: 1 .. count
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;

my $entry_class = 'App::Goto::Dir::Data::Entry'

#### constructor, object life cycle ############################################
sub new { #                                ~name, ~description, code --> .filter
    my ($pkg, $name, $description, $code) = @_;
    return unless defined $code and $name and $description and $code;
# check is_property
# check eval
    $code = 'sub { my $el = shift; return if ref $el ne "$entry_class";'.$code.'}';
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

#### attribute accessors ###############################################
sub name         { $_[0]->{'name'} }                                    #       --> ~name
sub rename       { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] } # ~name --> ~name
sub description  { $_[0]->{'description'} }                     #               --> ~description
sub redescribe   { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }# ~description --> ~description

#### entry API #################################################################
sub accept_entry    { #                                       .entry --> ?
    my ($self, $entry) = @_;
    return if ref ne $entry_class;
}

sub report {  #                                                      --> ~report
    my ($self, $width) = @_;
    $width //= 80;
    return substr( $self->{'name'}.': '.$self->{'description'}, 0, $width);
}
#### end ###############################################################

sub filter        {} #                --> .App::Goto::Dir::Data::ValueType::Relations
sub set_state {}     # ~list_name ~state --> ?
sub get_state {}     # ~list_name        --> ~state

1;
