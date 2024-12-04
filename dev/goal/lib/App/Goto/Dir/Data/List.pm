
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::Filter;

sub new {} # ~name ~decription, @.entry, @.filter -- ~order --> .list
sub state {} #                                              --> %state

sub name              {}   #                      --> ~name
sub description       {}   #                      --> ~description
sub rename            {}   #                ~name --> |~name
sub redescribe        {}   #         ~description --> |~description
sub sorting_order     {}   #                      --> ~order
sub set_sorting_order {}   #   ~order -- ?reverse --> |~order
sub reverse_sorting_order{}#                      --> |~order

sub all_entries       {}   #                      --> @.entry
sub entry_count       {}   #                      --> +
sub has_entry         {}   #               .entry --> ?
sub is_position       {}   #   +pos -- +add_range --> ?                 # add_range = 1 -> assume list is one elem longer
sub nearest_position  {}   #   +pos -- +add_range --> +pos              # +pos as input can be negative as in perl
sub get_entry_from_position{}#               +pos --> |.entry
sub add_entry         {}   #       .entry -- +pos --> |.entry
sub remove_entry      {}   #          .entry|+pos --> |.entry

sub all_filter_names  {}   #                      --> @.filter_name
sub add_filter        {}   #  .filter,      ~mode --> !.filter
sub remove_filter     {}   #  ~filter_name        --> !.filter
sub get_filter_mode   {}   #  ~filter_name        --> |~mode            # i x o m:= Inactive, eXclude, pass (OK), mark (with |)
sub set_filter_mode   {}   #  ~filter_name, ~mode --> |~mode

sub processed_entries {}   #                      --> @.entry           # filtered and ordered
sub report            {}   #            -- +width --> ~report

1;
