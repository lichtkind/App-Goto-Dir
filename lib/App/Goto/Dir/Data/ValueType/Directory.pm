
# directory value store and its formatting

package App::Goto::Dir::Data::ValueType::Directory;
use v5.18;
use warnings;
use File::Spec;

#### de- constructors ##################################################

sub new     {
    my ($pkg, $dir_str) = @_;
    return unless is_dir( $dir_str );
    $dir_str = normalize_dir( $dir_str );
    bless { value => $dir_str };
}

sub restate { bless {value => $_[1]} }
sub clone   { $_[0]->restate( $_[0]->state ) }
sub state   { $_[0]->value }

#### accessors #########################################################

sub get     { $_[0]->value }
sub set     { $_[0]->{'value'} = normalize_dir( $_[1] ) if is_dir( $_[1] ) }
sub value   { $_[0]->{'value'} }

#### predicates ########################################################

sub is_alive { -d expand_home_dir($_[0]->value) }
sub is_equal {
    my ($self, $dir_str) = @_;
    return 0 unless defined $dir_str;
    normalize_dir( $self->value ) eq normalize_dir( $dir_str );
}

#### display ###########################################################

sub format {
    my $self = shift;
    my $full_dir = shift // 0; #
    $full_dir ? expand_home_dir($self->value) : $self->value;
}

##### helper ###########################################################

sub is_dir {defined $_[0] and $_[0] and -d expand_home_dir($_[0]) }

sub expand_home_dir  {
    my $dir = shift;
    return unless defined $dir;
    return $dir unless substr($dir, 0, 1) eq '~';
    File::Spec->catdir( $ENV{'HOME'}, substr($dir, 1) );
}
sub compact_home_dir {
    my $dir = shift;
    return unless defined $dir;
    return $dir unless index($dir, $ENV{'HOME'}) == 0;
    return '~' if $dir eq $ENV{'HOME'};
    File::Spec->catdir( '~', substr( $dir, length($ENV{'HOME'}) + 1 ) );
}

sub normalize_dir {
    my $dir = shift;
    return unless defined $dir;
    $dir = expand_home_dir( $dir );
    $dir = File::Spec->rel2abs( $dir );
    $dir = File::Spec->canonpath( $dir );
    compact_home_dir( $dir );
}

#### end ###############################################################

1;

