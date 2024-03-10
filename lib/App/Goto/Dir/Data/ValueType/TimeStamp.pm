use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Data::ValueType::TimeStamp;

#### de- constructors ##################################################

sub new {
    my ($pkg) = @_;
    bless { value => 0 }
}

sub restate { bless {value => $_[1] + 0} }
sub state   { $_[0]->value }
sub clone   { $_[0]->restate( $_[0]->state ) }

#### getter/setter #####################################################

sub value    { $_[0]->{'value'} }
sub update   { $_[0]->{'value'} = _now() }
sub clear    { $_[0]->{'value'} = 0 }

sub is_empty           { not $_[0]->value }
sub is_older_then_age   { $_[0]->value < $_[1] }
sub is_older_then_period { $_[0]->value + $_[1] < _now() }
sub format {
    my $self = shift;
    my $time = shift // 0; # date only if zero
    my $sortable = shift // 0;

    my @t = _split( $self->value );
    if ($sortable) {
        return $time ? sprintf ( "%02d.%02d.%4s  %02d:%02d:%02d", 1900+$t[5], $t[4]+1, $t[3], $t[2], $t[1], $t[0])
                     : sprintf ( "%4s.%02d.%02d",                 1900+$t[5], $t[4]+1, $t[3] );
    } else {
        return $time ? sprintf ( "%02d.%02d.%4s  %02d:%02d:%02d", $t[3], $t[4]+1, 1900+$t[5], $t[2], $t[1], $t[0])
                     : sprintf ( "%02d.%02d.%4s",                 $t[3], $t[4]+1, 1900+$t[5]);
    }
}

##### helper ###########################################################

sub _now { time }
sub _split { my @t = localtime shift }

#### end ###############################################################

1;

