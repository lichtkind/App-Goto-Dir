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

    bless { dir => $dir,
            name  => $name_str // '', script => '',  note => '',
            list_pos => App::Goto::Dir::Data::ValueType::Position->new(),
            created  => App::Goto::Dir::Data::ValueType::TimeStamp->new( 1 ),
            deleted  => App::Goto::Dir::Data::ValueType::TimeStamp->new( 0 ),
            visited  => App::Goto::Dir::Data::ValueType::TimeStamp->new( 0 ),
            visits   => 0,
    }
}
sub clone   { $_[0]->restate( $_[0]->state ) }
sub restate { bless $_[1] if ref $_[1] eq 'HASH' }
sub state   {
    my ($self, $state) = (shift, {});
    $state->{ $_ } = $self->{ $_ }->state for qw/dir created deleted visited listpos/;
    $state->{ $_ } = $self->{ $_ }        for qw/script note visits/;
    $state;
}

#### time stamps #######################################################

sub age           { $_[0]->{'created'}->age_in_days }

sub visits        { $_[0]->{'visits'} }
sub days_not_visited { $_[0]->{'visited'}->is_empty ? -1 : $_[0]->{'visited'}->age_in_days } # -1 == never
sub visit_dir  {
    my ($self) = @_;
    $self->{'visited'}->update;
    ++$self->{'visits'};
}

# deleted date is more days ago than given number
sub is_expired    { ( ! $_[0]->{'deleted'}->is_empty and defined $_[1]
                     and $_[0]->{'deleted'}->age_in_days > $_[1] )     ? 1 : 0 }
sub delete        { $_[0]->{'deleted'}->is_empty ? $_[0]->{'deleted'}->update : 0}
sub undelete      { $_[0]->{'deleted'}->clear                                  }

#### accessors #########################################################

sub dir           { $_[0]->{'dir'}->format( $_[1] ) }
sub name          { $_[0]->{'name'} }
sub script        { $_[0]->{'script'} }
sub note          { $_[0]->{'note'} }

sub redirect      { $_[0]->{'dir'}->set( $_[1] ) }
sub rename        { $_[0]->{'name'}   = $_[1]   }
sub edit          { $_[0]->{'script'} = $_[1]   }
sub notate        { $_[0]->{'note'}   = $_[1]   }

my $property_call = { age    => sub { $_[0]->age  },
                      dir    => sub { $_[0]->dir   },
                      name   => sub { $_[0]->name   },
                      script => sub { $_[0]->script },
                      note   => sub { $_[0]->note   },
                      visits => sub { $_[0]->visits },
                  last_visit => sub { $_[0]->last_visit },
};
my $num_property = { age    => 1,
                     dir    => 0,
                     name   => 0,
                     script => 0,
                     note   => 0,
                     visits => 1,
                 last_visit => 1,
};

sub get {
    my ($self, $property) = @_;
    $property_call->{ $property }->( $self ) if is_property( $property );
}
sub is_property {
    my ($property) = @_;
    (defined $property and exists $property_call->{ $property }) ? 1 : 0;
}
sub is_nmeric_property {
    my ($property) = @_;
    $property->{$property} if is_property( $property );
}

sub list_pos      { $_[0]->{'list_pos'} }

#### write accessors ###################################################



##### helper ###########################################################
#### end ###############################################################

1;
