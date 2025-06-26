use v5.20;
use warnings;
use lib 'lib';
use Cwd;
use File::Find;
use File::Spec;
use FindBin qw($Bin);
BEGIN { chdir $Bin }

my $Project = 'App::Goto::Dir';
chdir '../goal';

my $lib_ret = eval "require 'App/Goto/Dir.pm';";

if          ($@) {say "$Project goal could not be loaded: $@!"}
elsif ($lib_ret) {say "$Project goal stub libs could be loaded!"}
else             {say "$Project goal stub  has bad return value!"}

# list all modules
# seen in dir structure
# with heading text
