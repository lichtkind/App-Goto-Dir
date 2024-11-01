use v5.18;
use warnings;

# load, store, access app configs

package App::Goto::Dir::Config;

sub load {
    $default = App::Goto::Dir::Config::Default::get();
}

sub store {}

sub write_destination {}

1;
