use v5.18;
use warnings;

use App::Goto::Dir::Data::ValueType::Directory;
use App::Goto::Dir::Data::ValueType::Position;
use App::Goto::Dir::Data::ValueType::TimeStamp;

package App::Goto::Dir::Data::Entry;

#### constructors + serialisation ######################################

sub new {
    my ($pkg, $dir_str, $name_str) = @_;
    my $dir = App::Goto::Dir::Data::ValueType::Directory->new( $dir_str );
    return unless ref $dir;  # only existing directories allowed

    bless { dir => $dir, name => $name_str // '', list_pos => {},
            script => '',  note => '',
            created => App::Goto::Dir::Data::ValueType::TimeStamp->new( 1 ),
            deleted => App::Goto::Dir::Data::ValueType::TimeStamp->new( 0 ),
            visited => App::Goto::Dir::Data::ValueType::TimeStamp->new( 0 ),
            visits  => 0,
    }
}
sub clone   { $_[0]->restate( $_[0]->state ) }
sub restate { bless $_[1] if ref $_[1] eq 'HASH' }
sub state   {
    my $state = {};
    $state->{ $_ } = $_[0]->{ $_ }->state for qw/dir created deleted visited listpos/;
    $state->{ $_ } = $_[0]->{ $_ }        for qw/script note visits/;
    $state;
}

#### time stamps #######################################################

sub age           { $_[0]->{'created'}->age_in_days }

sub last_visit    { $_[0]->{'visited'}->is_empty ? -1 : $_[0]->{'visited'}->age_in_days } # -1 == never
sub visits        { $_[0]->{'visits'} }
sub gets_visit  {
    my ($self) = @_;
    $self->{'visited'}->update;
    $self->{'visits'}++;
}

sub is_expired    { defined $_[1] and ! $_[0]->{'deleted'}->is_empty and $_[0]->{'deleted'}->age_in_days > $_[1] }
sub delete        { $_[0]->{'deleted'}->update if $_[0]->{'deleted'}->is_empty }
sub undelete      { $_[0]->{'deleted'}->clear                                  }

#### read accessors ############################################################

sub dir           { $_[0]->{'dir'}->format( $_[1] ) }
sub name          { $_[0]->{'name'} }
sub script        { $_[0]->{'script'} }
sub note          { $_[0]->{'note'} }

sub create_time   { $_[0]->{'create_time'} }
sub visit_time    { $_[0]->{'visit_time'} }
sub visit_count   { $_[0]->{'visits'} }
sub delete_time   { $_[0]->{'delete_time'} }
sub is_deleted    { $_[0]->{'delete_time'} ne 0 }
sub created_before {
    my ($self, $delta_ms) = @_;
    return unless defined $delta_ms;
    (_standardise_stamp($_[0]->{'create_time'}) cmp _std_format_delta( $_[1] )) > 0;
}
sub visited_before {
    my ($self, $delta_ms) = @_;
    return unless defined $delta_ms;
    return 0 unless $_[0]->{'visit_time'};
    (_standardise_stamp($_[0]->{'visit_time'}) cmp _std_format_delta( $_[1] )) > 0;
}
sub deleted_before {
    my ($self, $delta_ms) = @_;
    return unless defined $delta_ms;
    return 0 unless $_[0]->{'delete_time'};
    (_standardise_stamp($_[0]->{'delete_time'}) cmp _std_format_delta( $_[1] )) > 0;
}

#### write accessors ###########################################################

sub rename   { $_[0]->{'name'} = $_[1] }
sub edit     { $_[0]->{'script'} = $_[1] }
sub redirect {
    my ($self, $dir) = @_;
    $self->{'dir'} = _compact_home_dir( $dir );
    $self->{'full_dir'} = _expand_home_dir( $dir );
}

#### list API ##########################################################

sub member_of_lists  { keys %{ $_[0]->{'pos'} } }
sub get_list_pos     { $_[0]->{'pos'}{ $_[1] } if defined $_[1] }
sub add_to_list      { $_[0]->{'pos'}{ $_[1] } = $_[2] }
sub remove_from_list { delete $_[0]->{'pos'}{ $_[1] } }
#sub remove_from_special_lists { for (keys %{$_[0]->{'pos'}}) {delete $_[0]->{'pos'}{ $_ } if substr($_,0,1) =~ /\W/} }

#### end ###############################################################

1;
