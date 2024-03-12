use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Data::ValueType::Directory;

#### de- constructors ##################################################

sub new     {
    my ($pkg, $dir_str) = @_;
    return unless defined $dir_str and -d $dir_str;
    $dir_str = _compact_home_dir( File::Spec->canonpath($dir_str) );
    bless {value => $_[1]} if defined $_[1] and -d $_[1]

}
sub restate { bless {value => $_[1]} if defined $_[1] and $_[1] }
sub clone   { $_[0]->restate( $_[0]->state ) }
sub state   { $_[0]->value }

#### getter/setter #####################################################

sub get     { $_[0]->{'value'} }
sub set     { $_[0]->{'value'}  if defined $_[1] and $_[1] }

#### predicates ########################################################

sub is_alive { -d _expand_home_dir($_[0]->value) }
sub is_equal {
    my ($self, $dir_str) = @_;
    return 0 unless defined $dir_str;
    _expand_home_dir( $self->value) eq _expand_home_dir( File::Spec->canonpath( $dir_str) );
}

#### display ###########################################################

sub format {
    my $self = shift;
    my $full_dir = shift // 0; #
    $full_dir ? _expand_home_dir($_[0]->value) : $_[0]->value;
}

#### utils #############################################################

sub _compact_home_dir { (index($_[0], $ENV{'HOME'}) == 0) ? '~/' . substr( $_[0], length($ENV{'HOME'}) + 1 ) : $_[0] }
sub _expand_home_dir  { (substr($_[0], 0, 1) eq '~') ? File::Spec->catfile( $ENV{'HOME'}, substr($_[0], 2) ) : $_[0] }

#### end ###############################################################

1;

