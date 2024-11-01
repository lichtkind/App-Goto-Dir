use v5.18;
use warnings;

# inline default configs

package App::Goto::Dir::Config::Default;

sub get {
    return {
        file => {              data => 'places.yaml',
                               backup => 'places.bak.yaml',
                               return => 'last_choice',
                  },
       entry => {   discard_deleted_in_days => 30,
                               new_for_days => 40,
                            recent_for_days => 40,
                            overwrite_names => 0,
                            name_length_max => 6,
                  },
        list => { default_insert_position => -1,
                           start_app_with => '*current',
                             special_name => {
                                        all => 'all',
                                        new => 'new',
                                        bin => 'bin',
                                        now => 'now',
                                     broken => 'broken',
                                      named => 'named',
                            },
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
                                        dir => '<',
                             entry_position => '#',
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
}

1;
