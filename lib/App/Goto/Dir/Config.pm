use v5.18;
use warnings;
use File::Spec;
use YAML;

package App::Goto::Dir::Config;

our $file = "goto_dir_config.yml";
our $dfile = "goto_dir_config_default.yml";
our $loaded;
our (%command_shortcut, %option_shortcut, %option_name);

our $default = {
          file => {              data => 'places.yml',
                               backup => 'places.bak.yml',
                               return => 'last_choice',
                  },
         entry => {   name_length_max => 5,
                     position_default => -1,
              prefer_in_name_conflict => 'new', # old
                 prevent_dir_conflict => 0, #
                             dir_move => 1,
                           dir_exists => 1,
                    time_stamp_format => 'd.m.y  t',
                  },
          list => {     deprecate_new => 1209600,
                        deprecate_bin => 1209600,
                       deprecate_used => 1209600,
                           start_with => 'current',
                         name_default => 'use',
                         name_length_max => 6,
                         special_name => {
                                        all => 'all',
                                        new => 'new',
                                       used => 'used',
                                       idle => 'idle',
                                    defunct => 'defunct',
                                      named => 'named',
                                        run => 'run',
                                        bin => 'bin',
                             },
                  special_description => {
                                        all => 'all entries, even deleted ones',
                                        bin => 'recycling bin of deleted entries',
                                        new => 'recently created entries',
                                      stale => 'entries with not existing directories',
                                      named => 'entries with names',
                             },
                            sorted_by => 'visit_time',
                         sort_default => 'position',
                  },
          syntax => {           sigil => {
                              short_command => '-',
                                 entry_name => ':',
                                       help => '?',
                                       file => '<',
                             entry_position => '^',
                              special_entry => '+',
                               special_list => '@',
                                },
                        special_entry => {
                                       last => '_',
                                   previous => '-',
                                },
                     command_shortcut => {
                                        add => 'a',
                                     delete => 'd',
                                   undelete => 'u',
                                     remove => 'r',
                                       move => 'm',
                                       copy => 'c',
                                        dir => 'D',
                                      redir => 'R',
                                     script => 'S',
                                       name => 'N',
                                       sort => 's',
                                       list => 'l',
                             'list-special' => 'l-s',
                               'list-lists' => 'l-l',
                                 'add-list' => 'a-l',
                              'delete-list' => 'd-l',
                                'name-list' => 'N-l',
                            'describe-list' => 'D-l',
                                       help => 'h',
                                    version => 'v',
                                },
                      option_shortcut => {
                                        sort => {
                                           created => 'c',
                                               dir => 'D',
                                      'last_visit' => 'l',
                                          position => 'p',
                                              name => 'n',
                                            script => 'S',
                                            visits => 'v',
                                        },
                                        help => {
                                            basics => 'b',
                                          commands => 'c',
                                           install => 'i',
                                          settings => 's',
                                        },
                                },
                  },
};

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
