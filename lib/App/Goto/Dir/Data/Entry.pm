use v5.18;
use warnings;
use File::Spec;

package App::Goto::Dir::Data::Entry;

#### de- constructors ##################################################

sub new {
    my ($pkg, $dir, $name) = @_;  # return "directory $dir does not exist" unless -d $dir;
    my $now = _now();
    $dir //= '';
    bless { name => $name // '', script => '', pos => {},
            compact_dir => _compact_home_dir($dir), full_dir => _expand_home_dir($dir),
            create_time => _format_time_stamp($now), create_stamp => $now,
            visit_time   => 0,  visit_stamp => 0, visits => 0,
            delete_time => 0, delete_stamp => 0,  }
}
sub clone   { $_[0]->restate($_[0]->state) }
sub restate { bless $_[1] if ref $_[1] eq 'HASH' }
sub state   { return { map {$_ => $_[0]->{$_} } keys %{$_[0]} } }

#### list API ##########################################################

sub add_to_list      { $_[0]->{'pos'}{ $_[1] } = $_[2] }
sub remove_from_list { delete $_[0]->{'pos'}{ $_[1] } }
sub remove_from_special_lists { for (keys %{$_[0]->{'pos'}}) {delete $_[0]->{'pos'}{ $_ } if substr($_,0,1) =~ /\W/} }
sub get_list_pos     { $_[0]->{'pos'}{ $_[1] } if defined $_[1] }
sub member_of_lists  { keys %{ $_[0]->{'pos'} } }

#### ro attr ###########################################################

sub age           { defined $_[1] ? ($_[1] - $_[0]->{'create_stamp'}) : time - $_[0]->{'create_stamp'} }
sub unvisited     { not $_[0]->{'visit_stamp'} ? 0 : (defined $_[1]) ? ($_[1] - $_[0]->{'visit_stamp'}) : time - $_[0]->{'visit_stamp'} }
sub overdue       { not $_[0]->{'delete_stamp'} ? 0 : (defined $_[1]) ? ($_[1] - $_[0]->{'delete_stamp'}) : time - $_[0]->{'delete_stamp'} }
sub create_time   { $_[0]->{'create_time'} }
sub create_stamp  { $_[0]->{'create_stamp'} }
sub delete_stamp  { $_[0]->{'delete_stamp'} }
sub delete_time   { $_[0]->{'delete_time'} }
sub visit_stamp   { $_[0]->{'visit_stamp'} }
sub visit_time    { $_[0]->{'visit_time'} }
sub visit_count   { $_[0]->{'visits'} }
sub dir           { $_[0]->{'compact_dir'} }
sub full_dir      { $_[0]->{'full_dir'} }
sub name          { $_[0]->{'name'} }
sub script        { $_[0]->{'script'} }

#### rw attr ###########################################################

sub rename   { $_[0]->{'name'} = $_[1] }
sub edit     { $_[0]->{'script'} = $_[1] }
sub redirect {
    my ($self, $dir) = @_;
    $self->{'compact_dir'} = _compact_home_dir( $dir );
    $self->{'full_dir'} = _expand_home_dir( $dir );
}
sub visit {
    my ($self) = @_;
    $self->{'visit_time'} = _format_time_stamp( $self->{'visit_stamp'} = _now() );
    $self->{'full_dir'};
}
sub delete   { $_[0]->{'delete_time'} = _format_time_stamp( $_[0]->{'delete_stamp'} = _now() ) }
sub undelete { $_[0]->{'delete_stamp'} = $_[0]->{'delete_time'} = 0                            }

#### utils #############################################################

sub _compact_home_dir { (index($_[0], $ENV{'HOME'}) == 0) ? '~/' . substr( $_[0], length($ENV{'HOME'}) + 1 ) : $_[0] }
sub _expand_home_dir  { (substr($_[0], 0, 1) eq '~') ? File::Spec->catfile( $ENV{'HOME'}, substr($_[0], 2) ) : $_[0] }

sub _format_time_stamp { # sortable time stamp
    my @t = localtime shift;
    sprintf "%02d.%02d.%4s  %02d:%02d:%02d", $t[3], $t[4]+1, 1900+$t[5], $t[2], $t[1], $t[0];
}
sub _now { time }

#### end ###############################################################

1;

