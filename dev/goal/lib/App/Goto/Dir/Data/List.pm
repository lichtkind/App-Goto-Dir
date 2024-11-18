
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::Filter;

sub new {} # ~name ~decription, @.entry, @.filter --> .list
sub state {}               #                      --> %state ()

sub name             {}    #                      --> ~name
sub description      {}    #                      --> ~description
sub rename           {}    #                ~name --> ?~name
sub redescribe       {}    #         ~description --> ?~description

sub all_entries      {}    #                      --> @.entry
sub entry_count      {}    #                      --> +
sub has_entry        {}    #               .entry --> ?
sub get_entry_by_pos {}    #                 +pos --> ?.entry
sub add_entry        {}    #       .entry -- +pos --> ?.entry
sub remove_entry     {}    #                 +pos --> ?.entry

sub get_order        {}    #                      --> ~order
sub set_order        {}    # ~order               --> ?~order
sub processed_entries{}    #                      --> @.entry           # filtered and ordered
sub report           {}    #                      --> ~report

sub all_filter       {}    #                      --> @.filter
sub add_filter       {}    #  .filter,      ~mode --> ?.filter
sub remove_filter    {}    #  ~filter_name        --> ?.filter
sub get_filter_mode  {}    #  ~filter_name        --> ?~mode            # := - inactive
sub set_filter_mode  {}    #  ~filter_name, ~mode --> ?~mode            #    x eXclude
                                                                        #    o pass (OK)
                                                                        #    m mark

1;
