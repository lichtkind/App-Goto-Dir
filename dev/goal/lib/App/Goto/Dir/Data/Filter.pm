
# entry list filter to hide entries that fail a condition defined as ~code

package App::Goto::Dir::Data::Filter;
use v5.20;
use warnings;
use App::Goto::Dir::Data::ValueType::Relations;
use App::Goto::Dir::Data::Entry;

sub new {}   # ~name, ~description, ~code, %list_modes --> .filter

sub name          {} #                   --> ~name
sub description   {} #                   --> ~description
sub list_modes    {} #                   --> .::ValueType::Relations

sub rename        {} #             ~name --> ~name
sub redescribe    {} #      ~description --> ~description

sub accept_entry  {} #            .entry --> ?
sub report        {} #                   --> ~report

1;
