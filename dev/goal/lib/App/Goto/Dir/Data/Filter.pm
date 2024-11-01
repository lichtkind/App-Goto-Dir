
# entry list filter which may hides entries with defined properties

package App::Goto::Dir::Data::Filter;
use v5.18;
use warnings;
use App::Goto::Dir::Data::ValueType::Relations;

sub new {}  # ~code, ~filter_name -- ~filter_descrip. --> .filter
sub pass {} # .entry                                  --> ?

1;
