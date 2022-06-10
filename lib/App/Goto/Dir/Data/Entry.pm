use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Data::Entry;

#### constructors + serialisation ##############################################

sub new {
    my ($pkg, $dir, $name) = @_;
    return unless defined $dir; # return "directory $dir does not exist" unless -d $dir;
    my $now = _now();

    bless { name => $name // '', script => '', pos => {},
            dir => _compact_home_dir($dir),
            create_time => _create_time_stamp(),
            visit_time   => 0, visits => 0,    delete_time => 0,  }
}
sub clone   { restate( '', $_[0]->state) }
sub restate { bless $_[1] if ref $_[1] eq 'HASH' }
sub state   {
    my $state = { map {$_ => $_[0]->{$_} } keys %{$_[0]} };
    $state->{'pos'} = { map { $_ => $_[0]->{'pos'}{$_} } keys %{$_[0]->{'pos'}} };
    $state;
}

#### read accessors ############################################################

sub dir           { $_[0]->{'dir'} }
sub full_dir      { _expand_home_dir( $_[0]->{'dir'} ) }
sub name          { $_[0]->{'name'} }
sub script        { $_[0]->{'script'} }
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
sub visit {
    my ($self) = @_;
    $self->{'visit_time'} = _create_time_stamp();
    $self->{'visits'}++;
    $self->{'full_dir'};
}
sub delete   { $_[0]->{'delete_time'} = _create_time_stamp() unless $_[0]->is_deleted }
sub undelete { $_[0]->{'delete_time'} = 0                                             }

#### list API ##########################################################

sub member_of_lists  { keys %{ $_[0]->{'pos'} } }
sub get_list_pos     { $_[0]->{'pos'}{ $_[1] } if defined $_[1] }
sub add_to_list      { $_[0]->{'pos'}{ $_[1] } = $_[2] }
sub remove_from_list { delete $_[0]->{'pos'}{ $_[1] } }
#sub remove_from_special_lists { for (keys %{$_[0]->{'pos'}}) {delete $_[0]->{'pos'}{ $_ } if substr($_,0,1) =~ /\W/} }

#### utils #############################################################

sub _compact_home_dir { (index($_[0], $ENV{'HOME'}) == 0) ? '~/' . substr( $_[0], length($ENV{'HOME'}) + 1 ) : $_[0] }
sub _expand_home_dir  { (substr($_[0], 0, 1) eq '~') ? File::Spec->catfile( $ENV{'HOME'}, substr($_[0], 2) ) : $_[0] }
sub _create_time_stamp { # human readable time stamp
    my $time = shift // _now();
    my @t = localtime $time;
    sprintf "%4s.%02d.%02d.  %02d:%02d:%02d", 1900+$t[5], $t[4]+1, $t[3], $t[2], $t[1], $t[0];
}
sub _time_stamp_from_delta { _create_time_stamp( _now() + $_[0] ) if defined $_[0]  }
sub _now { time }

sub reformat_time_stamp { # understand keys y = year, m = month, d = day, t = time
    my ($stamp, $format) = @_;
    return unless defined $format;
    my $matched = $stamp =~ /(\d\d\d\d)\.(\d\d)\.(\d\d)\.\s+(\d\d:\d\d:\d\d)/;
    return unless $matched;
    my %stamp_content = (y => $1, m => $2, d => $3, t => $4);
    my $res = '';
    for my $i (1 .. length($format)) {
        my $char = substr($format, $i-1, 1);
        if (exists $stamp_content{ $char }){ $res .=  $stamp_content{ $char } }
        else                               { $res .= $char }
    }
    $res;
}

#### end ###############################################################

1;
