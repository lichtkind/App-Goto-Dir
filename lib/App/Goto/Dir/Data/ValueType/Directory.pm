use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Data::ValueType::Directory;

#### de- constructors ##################################################

sub new     {
    my ($pkg, $dir_str) = @_;
    return unless _is_dir( $dir_str );
    $dir_str = _normalize_dir( $dir_str );
    bless { value => $dir_str };
}

sub restate { bless {value => $_[1]} }
sub clone   { $_[0]->restate( $_[0]->state ) }
sub state   { $_[0]->value }

#### getter/setter #####################################################

sub get     { $_[0]->value }
sub set     { $_[0]->{'value'} = _normalize_dir( $_[1] ) if _is_dir( $_[1] ) }
sub value   { $_[0]->{'value'} }

#### predicates ########################################################

sub is_alive { -d _expand_home_dir($_[0]->value) }
sub is_equal {
    my ($self, $dir_str) = @_;
    return 0 unless defined $dir_str;
    _normalize_dir( $self->value ) eq _normalize_dir( $dir_str );
}

#### display ###########################################################

sub format {
    my $self = shift;
    my $full_dir = shift // 0; #
    $full_dir ? _expand_home_dir($self->value) : $self->value;
}

#### utils #############################################################

sub _is_dir {defined $_[0] and $_[0] and -d _expand_home_dir($_[0]) }

sub _expand_home_dir  {
    my $dir = shift;
    return unless defined $dir;
    return $dir unless substr($dir, 0, 1) eq '~';
    File::Spec->catdir( $ENV{'HOME'}, substr($dir, 1) );
}
sub _compact_home_dir {
    my $dir = shift;
    return unless defined $dir;
    return $dir unless index($dir, $ENV{'HOME'}) == 0;
    return '~' if $dir eq $ENV{'HOME'};
    File::Spec->catdir( '~', substr( $dir, length($ENV{'HOME'}) + 1 ) );
}

sub _normalize_dir {
    my $dir = shift;
    return unless defined $dir;
    $dir = File::Spec->rel2abs( $dir );
    $dir = File::Spec->canonpath( $dir );
    _compact_home_dir( $dir );
}

#### end ###############################################################

1;

