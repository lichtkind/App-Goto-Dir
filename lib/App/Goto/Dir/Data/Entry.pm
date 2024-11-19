
# storage cell for one directory and correlated data

package App::Goto::Dir::Data::Entry;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Directory;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::ValueType::TimeStamp;

#### constructors + serialisation ######################################
sub new {
    my ($pkg, $dir_str, $name, $description) = @_;
    my $dir = App::Goto::Dir::Data::ValueType::Directory->new( $dir_str );
    return 'only existing directories allowed as first argument' unless ref $dir;

    bless { dir => $dir,
            name  => $name // '', description  => $description // '',
            note => '',  script => '',  report => '', # not in use for now
            list_pos => App::Goto::Dir::Data::ValueType::Relations->new(),
            created  => App::Goto::Dir::Data::ValueType::TimeStamp->new( 1 ), # now = true (1)
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
    $state->{ $_ } = $self->{ $_ }        for qw/script report note visits/;
    $state;
}

#### accessors of displayed values #############################################
sub dir           { $_[0]->{'dir'}->format( $_[1] ) }
sub is_broken     { $_[0]->{'dir'}->is_alive ? 0 : 1}
sub name          { $_[0]->{'name'} }
sub description   { $_[0]->{'description'} }
sub script        { $_[0]->{'script'} }
sub note          { $_[0]->{'note'} }

sub redirect      { $_[0]->{'dir'}->set( $_[1] ) }
sub rename        { $_[0]->{'name'}        = $_[1]   }
sub redescribe    { $_[0]->{'description'} = $_[1]   }
sub rescript      { $_[0]->{'script'}      = $_[1]   }
sub notate        { $_[0]->{'note'}        = $_[1]   }

sub list_positions{ $_[0]->{'list_pos'} }
sub is_in_list    { $_[0]->{'list_pos'}->is_in_set( $_[1] ) }

#### time stamps #######################################################
sub days_old         { $_[0]->{'created'}->age_in_days }
sub days_not_visited { $_[0]->{'visited'}->is_empty ? -1 : $_[0]->{'visited'}->age_in_days } # -1 == never
sub visits           { $_[0]->{'visits'} }
sub visit_dir  {
    my ($self) = @_;
    $self->{'visited'}->update;
    ++$self->{'visits'};
}

# deleted more days ago than given number (arg 1)
sub is_deleted    { $_[0]->{'deleted'}->is_empty ? 0 : 1 }
sub is_expired    { ( $_[0]->is_deleted and defined $_[1] and $_[0]->{'deleted'}->age_in_days > $_[1] ) ? 1 : 0 }
sub delete        { $_[0]->is_deleted ? 0 : $_[0]->{'deleted'}->update }
sub undelete      { $_[0]->is_deleted ? $_[0]->{'deleted'}->clear : 0 }

#### universal accessor ########################################################
my $cmp_value = { age    => sub { $_[0]->{'created'}->get()  },
             last_visit  => sub { $_[0]->{'visited'}->get() },
             delete_time => sub { $_[0]->{'deleted'}->get() },
             dir         => sub { $_[0]->dir(1) }, # compare full dirs
             name        => sub { $_[0]->name   },
             description => sub { $_[0]->description   },
             script      => sub { $_[0]->script },
             note        => sub { $_[0]->note   },
             visits      => sub { $_[0]->visits },
};
my $property_is_numeric = { age  => 1,       last_visit => 1,   delete_time => 1,
                           dir   => 0,           visits => 1,
                           name  => 0,      description => 0,
                           note  => 0,           script => 0,
};

sub is_property {
    my ($property) = @_;
    (defined $property and exists $cmp_value->{ $property }) ? 1 : 0;
}
sub get_property  {
    my ($self, $property) = @_;
    $cmp_value->{ $property }->( $self ) if is_property( $property );
}
sub cmp_property {
    my ($self, $property, $entry2) = @_;
    return unless is_property( $property ) and ref $entry2 eq __PACKAGE__;
    $property_is_numeric->{$property}
        ? ($self->get_property( $property ) <=> $entry2->get_property( $property ))
        : ($self->get_property( $property ) cmp $entry2->get_property( $property ));
}
#### end ###############################################################
1;
