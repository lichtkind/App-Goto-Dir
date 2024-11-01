
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::Entry;

sub new { }               # @.entry, ~name -- ~decription  --> .
sub state { }             #                                --> ~name -- ~decription

sub add_entry { }         # .entry -- +pos --> ?
sub remove_entry { }      #           +pos --> .entry
sub get_entry { }         #           +pos --> .entry

sub all_entries { }       #                --> @.entry
sub processed_entries { } #                --> @.entry # filtered and ordered

sub set_filter_state { }  # ~filter ~state --> ?
sub get_filter_state { }  # ~filter        --> ~state

sub set_order        { }  # ~order         --> ?
sub get_order        { }  #                --> ~order


1;
