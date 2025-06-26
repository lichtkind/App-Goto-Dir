
# exec user CLI commands

package App::Goto::Dir::Command;
use v5.20;
use warnings;
use App::Goto::Dir::Data;
use App::Goto::Dir::Help;


sub add_list    {}  #                        ~list_name, ~decription --> !
sub remove_list {}  #                        ~list_name              --> !
sub change_list {}  #                        ~list_name              --> !
sub show_lists  {}  #                                                -->

sub add_entry    {} #        ~dir -- ~name, ~description, ~list_name --> !
sub delete_entry {} #        $ID                                     --> !  # $ID  := ~name|#pos -- ~list
sub select_entry {} #        $ID                                     --> !
sub copy_entry   {} #        $ID_source -- $ID_target                --> !
sub move_entry   {} #        $ID_source -- $ID_target                --> !
sub remove_entry {} #        #pos       -- ~list_name                --> !

sub show_help    {} #

1;
