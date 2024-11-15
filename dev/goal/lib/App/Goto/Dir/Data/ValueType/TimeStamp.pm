
# store for one time information, calculation, formatting

package App::Goto::Dir::Data::ValueType::TimeStamp;
use v5.20;
use warnings;

sub new      {} #                       ? --> .
sub get      {} #                         --> +stamp
sub set      {} #                  +stamp --> +stamp
sub value    {} #                         --> +stamp
sub update   {} #                         --> +stamp
sub clear    {} #                         --> +stamp

sub is_empty {} #                         --> ?
sub age      {} #                         --> +age
sub age_in_days {} #               +stamp --> +...
sub is_older_then_stamp {} #       +stamp --> ?
sub is_older_then_period {} #        +age --> ?

sub format {} #  -- ?also_time, ?sortable --> ~format

1;
