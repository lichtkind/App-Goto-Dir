
# storage cell for one directory and correlated data

package App::Goto::Dir::Data::Entry;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Directory;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::ValueType::TimeStamp;

sub new {} #      ~dir -- ~name, ~description --> .entry

sub dir           {} #                        --> ~dir
sub is_broken     {} #                        --> ?
sub name          {} #                        --> ~name
sub description   {} #                        --> ~description
sub script        {} #                        --> ~script
sub note          {} #                        --> ~note

sub redirect      {} #                   ~dir --> |~dir
sub rename        {} #                  ~name --> |~name
sub redescribe    {} #           ~description --> |~description
sub rescript      {} #                ~script --> |~script
sub notate        {} #                  ~note --> |~note

sub list_positions{} #                        --> .::ValueType::Relations
sub is_in_list    {} #             ~list_name --> ?

#### time stamps #######################################################
sub days_old         {} #                     --> +
sub days_not_visited {} #                     --> +
sub visits           {} #                     --> +visists
sub visit_dir        {} #                     --> +visists

# deleted more days ago than given number (arg 1)
sub is_deleted    {} #                        --> ?
sub is_expired    {} #                  +days --> ?
sub delete        {} #                        --> +age_sec
sub undelete      {} #                        --> +age_sec

#### universal accessor ########################################################
sub is_property   {} # ~property_name         --> ?
sub get_property  {} # ~property_name         --> |$value
sub cmp_property  {} # ~property_name, .entry --> 1|0|-1

1;
