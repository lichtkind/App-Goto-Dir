
# load, store, access app configs

package App::Goto::Dir::Config;
use v5.20;
use warnings;
use App::Goto::Dir::Config::Default;

sub load {
    my $default = App::Goto::Dir::Config::Default::get();
}

sub store {}

sub write_destination {}

1;
