
# state of a relations between an object and a list of objects

package App::Goto::Dir::Data::ValueType::Relation;
use v5.20;
use warnings;

sub new        {} #                   --> .

sub get_in     {} # ~set_name         -->   $val
sub set_in     {} # ~set_name, $val   -->   $val
sub add_set    {} # ~set_name, $val   -->   $val
sub remove_set {} # ~set_name         -->   $val

sub list_sets  {} #                   --> @~set_name

1;
