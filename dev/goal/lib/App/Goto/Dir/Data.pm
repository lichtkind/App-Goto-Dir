
# load, store, manage all dir entries in lists with filters

package App::Goto::Dir::Data;
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::Filter;
use App::Goto::Dir::Data::List;

sub new { }   #                          --> .
sub state {}  #                          --> %data
sub restate {} #                  %data  --> .

sub get_current_list_name {}  #                                         --> ~list_name
sub set_current_list_name {}  #  ~lname                                 --> ?~list_name

sub create_list {}            #  ~lname -- ~ldescription                --> .list
sub delete_list {}            #  ~lname                                 --> ?.list
sub get_list {}               #         -- ~lname                       --> .list
sub get_list_names {}         #                                         --> @~list_name
sub list_report {}            #         -- +width                       --> ~report

sub create_filter {}          #  ~fname, ~fdescription, ~fcode, %lmodes --> .filter
sub delete_filter {}          #  ~fname                                 --> ?
sub get_filter {}             #  ~fname                                 --> .filter
sub get_filter_names {}       #                                         --> @~fname

sub create_entry {}           #  ~dir -- ~ename, ~edescription          --> .entry
sub delete_entry {}           #  ~ename                                 --> ?
sub get_entry {}              #  ~ename                                 --> .entry
sub all_entry_names {}        #                                         --> @~ename

1;
