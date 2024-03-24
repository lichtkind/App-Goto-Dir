use v5.18;
use warnings;

package App::Goto::Dir::Config;

use File::Spec;
use YAML;
use App::Goto::Dir::Config::Default;

our $file = "goto_dir_config.yml";          # fall back
our $dfile = "goto_dir_config_default.yml";
our $loaded;
our (%command_shortcut, %option_shortcut, %option_name);

sub load {
    __PACKAGE__->reset unless -r $file;
    $loaded = YAML::LoadFile($file);

    my $option = $loaded->{'syntax'}{'option_shortcut'};
    my $command = $loaded->{'syntax'}{'command_shortcut'};
    for my $cmd (keys %$option){
        for my $opt (keys %{$option->{$cmd}}){
            for my $l (1 .. length $opt){
                my $part_opt = substr $opt, 0, $l;
                if (exists $option_name{$cmd}{$part_opt}){ $option_name{$cmd}{$part_opt} = 0 }
                else                                     { $option_name{$cmd}{$part_opt} = $opt }
            }
        }
    }
    for my $cmd (keys %$option){
        $option_shortcut{$cmd} = {  map { $option->{$cmd}{$_} => $_ } keys %{$option->{$cmd}}  };
    }
    %command_shortcut = map { $command->{$_} => $_ } keys %$command;

    $loaded;
}

sub reset {
    YAML::DumpFile( $file, $default );
    YAML::DumpFile( $dfile, $default );
}

sub save {
    $loaded = shift if ref $_[0] eq 'HASH';
    YAML::DumpFile( $file, $loaded );
}

1;
