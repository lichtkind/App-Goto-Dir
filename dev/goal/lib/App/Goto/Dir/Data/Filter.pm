
# entry list filter which may hides entries with defined properties

package App::Goto::Dir::Data::Filter;
use v5.20;
use warnings;
use App::Goto::Dir::Data::Entry;
use App::Goto::Dir::Data::ValueType::Relations;

sub new {}       # ~code, ~filter_name -- ~filter_description --> .filter

sub name          {} #                --> ~name
sub description   {} #                --> ~description
sub filter        {} #                --> .App::Goto::Dir::Data::ValueType::Relations

sub rename        {} #          ~name --> ~name
sub redescribe    {} #   ~description --> ~description

sub accept_entry  {} #         .entry --> ?
sub report {}        #                --> ~report

1;
