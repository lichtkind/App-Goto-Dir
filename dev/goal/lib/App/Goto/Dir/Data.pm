use v5.18;
use warnings;

# load, store, manage all dir entries in lists with filters

package App::Goto::Dir::Data;

sub new { }   # %data, %config --> .
sub state {}  #                --> %data
# sub restate {}

sub get_current_list_name {}  #                                      --> ~list_name
sub set_current_list_name {}  #  ~list_name                          --> ?

sub create_list {}            #  ~list_name -- ~list_description     --> .list
sub delete_list {}            #  ~list_name                          --> ?
sub get_list {}               #             -- ~list_name            --> .list
sub get_list_names {}         #                                      --> @~list_name

sub create_filter {}          #  ~code, ~filter_name -- ~description --> .filter
sub delete_filter {}          #  ~filter_name                        --> ?
sub get_filter {}             #  ~filter_name                        --> .filter
sub get_filter_names {}       #                                      --> @~filter_name

1;
