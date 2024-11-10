
# list of dir entries, handles their positions

package App::Goto::Dir::Data::List;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::Entry;

sub new {} # ~name -- ~decription, @.entry, @.filter --> .list
sub state {}              #                      --> %state ()

sub add_entry { }         # .entry -- +pos       --> ?
sub remove_entry {}       #           +pos       --> .entry
sub get_entry {}          #           +pos       --> .entry

sub all_entries {}        #                      --> @.entry
sub processed_entries {}  #                      --> @.entry # filtered and ordered

sub add_filter  {}        # .filter ~state       --> .filter
sub remove_filter {}      # ~filter_name         --> .filter
sub get_state  {}         # ~filter_name         --> ~state
sub set_state  {}         # ~filter_name, ~state --> ~state


sub get_order        {}   #                      --> ~order
sub set_order        {}   # ~order               --> ~order


1;
