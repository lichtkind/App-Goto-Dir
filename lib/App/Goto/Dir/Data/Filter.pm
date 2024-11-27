
# entry list filter to hide entries that fail a condition defined as ~code

package App::Goto::Dir::Data::Filter;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::Entry;

my $entry_class = 'App::Goto::Dir::Data::Entry';

#### constructor, object life cycle ############################################
sub new {  #                              ~name, ~description, ~code --> .filter
    my ($pkg, $code, $name, $description) = @_;
    return 'need 3 arguments: code and name, and a description'
         unless defined $description and $description and $name and $code;
    my $full_code = _complete_code( $code );
    return "filter $name got bad code: $code" unless $full_code;
    my $ref = eval $full_code;
    return "filter $name got bad code: $full_code: $@" if $@;   # smoke test
    bless { name => $name, description => $description, code => $full_code, ref => $ref,
           modes => App::Goto::Dir::Data::ValueType::Relations->new(), };
}
sub restate {
    my ($pkg, $state) = @_;
    return if ref $state ne 'HASH';
    my $self = { %$state };
    my $full_code = _complete_code( $self->{'code'} );
    return "filter $self->{name} got bad code: $self->{code}" unless $full_code;
    $self->{'ref'} = eval $full_code;
    return "filter $self->{name} got bad code: $full_code: $@" if $@;
    $self->{'modes'} = App::Goto::Dir::Data::ValueType::Relations->restate( $self->{'modes'} );
    bless $self;
}
sub state  {
    return { name => $_[0]->{'name'}, description => $_[0]->{'description'},
             code => $_[0]->{'code'},       modes => $_[0]->{'modes'}->state };
}

#### attribute accessors ###############################################
sub name         { $_[0]->{'name'} }                                    #        --> ~name
sub rename       { $_[0]->{'name'} = $_[1] if defined $_[1] and $_[1] } #  ~name --> ~name
sub description  { $_[0]->{'description'} }                             #        --> ~description
sub redescribe   { $_[0]->{'description'} = $_[1] if defined $_[1] and $_[1] }
                                                                  # ~description --> ~description
sub list_modes   { $_[0]->{'modes'} }                                   #        --> .::ValueType::Relations

#### entry API #################################################################
sub accept_entry { $_[0]->{'ref'}->($_[1]) }                            # .entry --> ?
sub report       {                                                      #        --> ~report
    my ($self, $width) = @_;
    $width //= 80;
    return substr( $self->{'name'}.': '.$self->{'description'}, 0, $width);
}

##### helper ###########################################################
sub _complete_code {
    my $code = shift;
    return unless defined $code and $code;
    return $code if length($code) > 5 and substr($code,0,3) eq 'sub';
    my $return = "sub { \n return 0 if ref ".'$_[0]'." ne '$entry_class';\n";
    my $temp = $code;
    while ($temp =~ /\$(\w+)/) {
        my $found = $1;
        return unless App::Goto::Dir::Data::Entry::is_property( $1 );
        $return .= 'my $'.$1.' = $_[0]->get_property("'.$1.'");';
        $temp = substr($temp, $+[1]);
    }
    $return .= "return 0 + ( $code ); }";
}
#### end ###############################################################

1;
