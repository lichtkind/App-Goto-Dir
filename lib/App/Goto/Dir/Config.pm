use v5.18;
use warnings;

# load, store, access app configs

package App::Goto::Dir::Config;

use File::Spec;
use File::HomeDir;
use YAML;
use App::Goto::Dir::Config::Default;

my $file_name = File::Spec->catfile( File::HomeDir->my_home, '.config', 'goto-dir', 'settings.yaml');
my $data;

sub load {
    my $default = App::Goto::Dir::Config::Default::get;
    return fall_back() unless -r $file_name;

    $data = YAML::LoadFile( $file_name );
    $data = (ref $data eq 'ARRAY') ? $data->[0] : $data;
    $data = (ref $data eq 'HASH') ? $data : $default;
    return get();
}

sub fall_back {
    my $data = App::Goto::Dir::Config::Default::get;
}

sub save { YAML::DumpFile( $file_name, $data ) }

sub get {
    my (@keys) = @_;
    my $ret = $data;
    for my $k (@keys){
        return unless exists $ret->{ $k };
        $ret = $ret->{ $k };
    }
    return $ret;
}

sub set {
    my ($value, @keys) = @_;
    my $d = $data;
    return unless @keys;
    my $last_key = pop @keys;
    for my $k (@keys){
        return unless exists $d->{ $k };
        $d = $d->{ $k };
    }
    return unless exists $d->{ $last_key } and ref $value eq ref $d->{ $last_key };
    $d->{ $last_key } = $value;
}

1;
