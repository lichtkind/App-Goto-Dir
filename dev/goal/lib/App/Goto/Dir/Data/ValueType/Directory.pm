
# store and formatting for a directory string

package App::Goto::Dir::Data::ValueType::Directory;
use v5.20;
use warnings;
use File::Spec;

sub new   {}    # ~dir --> .

sub get   {}    #      --> ~clean_compact_dir
sub set   {}    # ~dir --> ~clean_compact_dir    # ~dir has to exist
sub value {}    #      --> ~clean_compact_dir

sub is_alive {} #      --> ?
sub is_equal {} # ~dir --> ?
sub format   {} # ?    --> 0: ~clean_compact_dir| 1: ~clean_full_dir

1;
