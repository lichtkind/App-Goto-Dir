
# entry list filter which may hide entries with defined properties

package App::Goto::Dir::Data::Filter;
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;

my $entry_class = 'App::Goto::Dir::Data::Entry'

#### constructor, object life cycle ############################################
sub new { # #               ~name, ~description, ~code, %list_modes --> .filter
    my ($pkg, $name, $description, $code, $modes) = @_;
    return 'need 4 arguments: name, description, code and filter mode hash'
        unless defined $states and $name and $description and $code and ref $states eq 'HASH';
    my $full_code = _complete_code( $code );
    return "filter $name got bad code: $code" unless $full_code;
    my $ref = eval $full_code;
    return "filter $name got bad code: $full_code: $@" if $@;
    # smoke tst with ref
    bless { name => $name, description => $description, code => $code, ref => $ref
           modes => App::Goto::Dir::Data::ValueType::Relations->restate( $modes ), };
}
sub restate {
    my %self = %{$_[0]};
    my $full_code = _complete_code( $self->{'code'} );
    return "filter $name got bad code: $self->{code}" unless $full_code;
    $self->{'ref'} = eval $full_code;
    return "filter $name got bad code: $full_code: $@" if $@;
    $self->{'modes'} = App::Goto::Dir::Data::ValueType::Relations->restate( $self->{'modes'} );
    bless $self;
}
sub state  { return {name => $_[0]->{'name'}, description => $_[0]->{'description'},
                     code => $_[0]->{'code'},      states => $_[0]->{'states'}->state } }

#### attribute accessors ###############################################
sub name         { $_[0]->{'name'} }                                    #       --> ~name
sub rename       { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] } # ~name --> ~name
sub description  { $_[0]->{'description'} }                     #               --> ~description
sub redescribe   { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }# ~description --> ~description
sub list_modes   { $_[0]->{'modes'} }                                  #       --> .::ValueType::Relations

#### entry API #################################################################
sub accept_entry    { #                                       .entry --> ?
    my ($self, $entry) = @_;
    return if ref ne $entry_class;
    $self->{'ref'}->($entry);
}

sub report {  #                                                      --> ~report
    my ($self, $width) = @_;
    $width //= 80;
    return substr( $self->{'name'}.': '.$self->{'description'}, 0, $width);
}

##### helper ###########################################################
sub _complete_code {
    my $code = shift;
#    $code = 'sub { my $el = shift; return if ref $el ne "$entry_class";'.$code.'}';
}
#### end ###############################################################

1;
