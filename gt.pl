#!/usr/bin/perl

use v5.18;
use lib 'lib';
use warnings;
no warnings  qw/experimental::smartmatch/;
use feature qw/switch/;
use Cwd;
use FindBin;
use File::Spec;

my $VERSION = 0.8;
my %command = (add =>'a', delete =>'d', name =>'n', move =>'m', sort =>'s',
              list =>'l', undo =>'<', redo =>'>', last =>'_', help =>'h');
my %cmd; %cmd = map { die "command $_ is defiend twice" if $cmd{$command{$_}} ;$command{$_} => $_ } keys %command;
my %sort_shortcut = ('' => 'position', p => 'position', n => 'name', v => 'visits', l => 'last_visit', c => 'creation_time', d => 'dir');
my $sep = '[,:->]'; # arg separator character
my $char = '[a-zA-Z0-9]';
my %file = (places => 'places.yaml',  backup => 'places.yaml.bak',      destination => 'last_choice');

our $cwd = Cwd::cwd();
chdir $FindBin::Bin;
require App::Goto::Dir::Data;
my $data = (-r $file{'places'}) ? YAML::LoadFile( $file{'places'} ) : {archive =>[], current => [], sorted_by => 'position'};
my ($sorted_by, $list_name, $dir_list, %pos_of_name, @next_data) = ($data->{'sorted_by'});
my @past_data = ($data);
$data = clone_data($data);
select_list('current');

if (@ARGV){
    given ( $ARGV[0] ) {
        when ($command{'last'}) { exit goto_path($data->{'last_choice'}{'list'}, $data->{'last_choice'}{'position'}) }
        when (/^(\d+)(\/.+)?$/) { # numeric selection
            exit goto_path('current', $1, $2) if check_index($dir_list, $1);
            say "destinations have to be numbers between 0 and $#$dir_list";
        }
        when (/^([a-zA-Z0-9]+)(\/.+)?$/) { #catching names
            exit goto_path('current', $pos_of_name{$1}, $2) if defined $pos_of_name{$1};
            print 'no such name, available are just: ';
            say map {"$_ "} keys %pos_of_name;
        }
    }
}
else {
main: while (1){
        say "App::Dir::Goto list '$list_name', sorted by '$sorted_by' (h <Enter> for help):";
        my @list_order = $sorted_by eq 'position' ? 0 .. $#$dir_list : sort {$dir_list->[$a]{$sorted_by} cmp $dir_list->[$b]{$sorted_by}} 0 .. $#$dir_list;
        printf "[%2s] %6s    %s\n", $_, $dir_list->[$_]{name}//'', $dir_list->[$_]{dir} for @list_order;

input:  print ">";
        chomp (my $input = <STDIN>);
        given ( $input ) {
            when (/^$command{'add'}$sep?(\d*)$sep?($char*)$/) {
                my $dir = $cwd;
                $dir = '~/' . substr( $dir, length($ENV{'HOME'}) + 1 ) if index($dir, $ENV{'HOME'}) == 0;
                for (@$dir_list){ next main if $_->{'dir'} eq $dir}
                my $pos = $1; $pos = $#$dir_list+1 unless check_new_index($dir_list, $pos);
                splice @$dir_list, $pos, 0, {dir => $dir, creation_time => now(), last_visit => 0, visits => 0};
                $dir_list->[$pos]{'name'} = $2 if $2;
                say "remember directory $dir at position $pos and and under ".($2 ? '': 'no')." name $2";
            }
            when (/^$command{'name'}$sep?($char+)$sep?($char*)$/){
                my $pos = check_ID($dir_list, $1);
                error ("index $1 is not a valid list position or name") unless defined $pos;
                error ("$2 is not a valid name (A-Z,a-z only, max. 5 chars)") if $2 and ($2 =~ /[^A-Za-z0-9]/ or length $2 > 5);
                if (length($2)){
                    for (@$dir_list) { delete $_->{'name'}  if $_->{'name'} eq $2 }
                    $dir_list->[$pos]{'name'} = $2;
                    $pos_of_name{ $2 } = $pos;
                    say "named entry $pos as $2";
                } elsif (exists $dir_list->[$pos]{'name'}) {
                    my $name = delete $dir_list->[ $pos ]{'name'};
                    delete $pos_of_name{ $name };
                    say "deleted path name $name";
                }
            }
            when (/^$command{'move'}($char+)$sep?($char*)$sep?($char*)$/) {
                my ($from, $lname, $to) = (check_ID($dir_list, $1), $2, $3);
                error ("index $1 is not a valid list position or name") unless defined $from;
                ($lname, $to) = ($list_name, $lname) if $lname !~ /\D/;
                error ("there is to dir list named $lname") if ref $data->{ $lname } ne 'ARRAY';
                $to ||= $#{$data->{ $lname }}+1;
                error ("index $to is not a valid list position") unless check_new_index($data->{ $lname }, $to);
                splice( @{$data->{ $lname }}, $to, 0, splice( @$dir_list, $from, 1));
                say "moved entry from position $from to $to of list $lname";
            }
            when (/^$command{'delete'}$sep?($char*)$/){
                my $pos = check_ID($dir_list, $1);
                error ("identifier $1 is not a valid list position or name $pos") unless defined $pos;
                my $entry = splice @$dir_list, $pos, 1;
                delete $pos_of_name{ $entry->{'name'} } if exists $entry->{'name'};
            }
            when (/^$command{'sort'}$sep?(\w){0,1}$/){
                my $crit = $sort_shortcut{$1};
                error ("'$1' is not a valid sorting criterion, try 'p','n','v','l','c','d' or empty") unless defined $crit;
                $data->{'sorted_by'} = $sorted_by = $crit;
            }
            when (/^$command{'list'}$sep?(\w*)$/){
                my @list = sort grep {ref $data->{$_} eq 'ARRAY'} keys %$data;
                if ((my $lname = $1) ne ''){
                    $lname = $list[$lname] if $lname =~ /^\d+$/ and $1 >= 0 and $1 < @list;
                    if (ref $data->{$lname} eq 'ARRAY'){ select_list($lname)}
                    else                               { error ("'$lname' is not a valid index or list name, try 0..$#list or: @list") }
                } else {
                    say "available directory lists: ";
                    printf "[%2s]   %02d  %s\n", $_, int @{$data->{$list[$_]}}, $list[$_] for 0..$#list;
                    while (1){
                        print ">>";
                        chomp (my $input = <STDIN>);
                        last if $input eq '';
                        $input = $list[$input] if $input =~ /^\d+$/ and $input >= 0 and $input < @list;
                        (say "'$input' is not a valid index or list name, try 0..$#list or: @list"), next unless ref $data->{$input} eq 'ARRAY';
                        select_list( $input );
                        goto main;
                    }
                }
            }
            when ($command{'undo'}){
                error ("there are no recorded undo step to be redone") unless @past_data;
                unshift @next_data, $data;
                pop @past_data;
                $data = pop @past_data;
                select_list( $list_name );
                say "undo last command";
                goto main;
            }
            when ($command{'redo'}){
                error ("there are no recorded undo step to be redone") unless @next_data;
                push @past_data, $data;
                $data = shift @next_data;
                select_list( $list_name );
                say "redo last undo";
                goto main;
            }
            when (/^$command{'help'}$sep?(\w*)$/){ help( $1 );  goto input  }
            when ($command{'last'})              { exit goto_path( @{$data->{'last_choice'}}{qw/list position addon/} )}
            when (/^(\d+)(\/.+)?$/)              {
                error ("index $1 is not a valid dir list position") unless check_index($dir_list, $1);
                exit goto_path($list_name, $1, $2);
            }
            when (/^$sep($char+)(\/.+)?$/) {
                error ("$1 is unknown directory name") unless defined $pos_of_name{$1};
                exit goto_path($list_name, $pos_of_name{$1}, $2);
            }
            when ('')  { exit write_return_path('.') }
            default    { help();  goto input   }
        }
        write_data( $data );
        push @past_data, $data;
        shift @past_data if @past_data > 22;
        @next_data = ();
        $data = clone_data($data);
        select_list( $list_name );
    }
}

sub clone_data {
    my $data = shift;
    return $data unless ref $data;
    return [map {clone_data($_)} @$data] if ref $data eq 'ARRAY';
    return {map {$_ => clone_data( $data->{$_} )} keys %$data} if ref $data eq 'HASH';
}
sub select_list { # change displayed list
    my $new_list_name = shift;
    return unless ref $data->{ $new_list_name } eq 'ARRAY';
    $list_name = $new_list_name;
    $dir_list = $data->{ $new_list_name };
    %pos_of_name = map { $dir_list->[$_]{'name'} => $_ } grep {exists $dir_list->[$_]{'name'}} 0 .. $#$dir_list;
}

sub check_index     { my ($list, $i) = @_; $i =~ /\d+/ and ref $list eq 'ARRAY' and $i >= 0 and $i <= $#$list}
sub check_new_index { my ($list, $i) = @_; $i =~ /\d+/ and ref $list eq 'ARRAY' and $i >= 0 and $i <= @$list}
sub check_ID  {
    my ($list, $i) = @_;
    return unless ref $list eq 'ARRAY';
say "check $list, $i";
    return $#$list if not defined $i or (not $i and $i != 0);
    check_index(@_) ? $i : $pos_of_name{$i};
}
sub error { say 'Input Error: ' . shift; goto input }

sub now { # sortable time stamp
    my @t = localtime;
    sprintf "%4s %02d.%02d. %02d:%02d:%02d", 1900+$t[5], $t[4], $t[3], $t[2], $t[1], $t[0];
}

sub goto_path {
    my ($list_name, $list_pos, $addon) = @_;
    return unless ref $data->{$list_name} eq 'ARRAY';
    my $list = $data->{$list_name};
    return unless defined $list_pos and int $list_pos == $list_pos and $list_pos >= 0 and $list_pos < @$list;

    my $path = $list->[$list_pos]->{'dir'};
    $path = File::Spec->catfile( $ENV{'HOME'}, substr($path, 2) ) if substr($path, 0, 1) eq '~';
    $path = File::Spec->catfile( $path, $addon ) if defined $addon;
    error("could not find directory '$path'") unless -d $path;
    $list->[$list_pos]->{'last_visit'} = now();
    $list->[$list_pos]->{'visits'}++;
    $data->{'last_choice'} = {list => $list_name, position => $list_pos, addon => $addon};
    write_data($data);
    write_return_path($path);
}
sub write_data {
    rename $file{'places'}, $file{'backup'};
    YAML::DumpFile( $file{'places'}, $_[0] );
}
sub write_return_path {
    open my $FH, '>', $file{'destination'};
    print $FH $_[0];
    0;
}

sub help {
    my $what = shift;
    if (not $what or $what eq 'txt'){
        say <<EOH;

          Help of          App::Dir::Goto        Version $VERSION

  Command line tool gt (short for goto) changes the working dir like cd.
  It remembers a set of directories you can address by number or name.
  <pos> stands for a position number and <name> for name
  of dir entry. <p/n> means one of both (a path identifier).
  To optionally address a subdir just write <p/n>/sub/dir.
  Use 'gt <pos>' or 'gt <name>' or just 'gt' to open interactive mode.
  There you type commands that will be completed by <Enter>.
  Command arguments can be separated by [,:->] (mostly optional).
  Please press just <Enter> to exit the interactive mode.
EOH
    }
    if (not $what or $what eq 'cmd'){
        say <<EOH;

  commands for managing list entries:

  <pos>              go to directory listed on position (in [])
  :<name>            go to dir listed under name (right beside <pos>)
  $command{'last'}                  go to dir gone to last time
  $command{'add'}\[<pos>\[:<name>\]\]  add current dir on <pos> (default -1) as <name>
  $command{'delete'}\[<p/n>\]           delete dir entry (default -1)
  $command{'name'}<pos>:<name>      add Name to directory (max. 5 alphanumeric char.)
  $command{'name'}<p/n>             delete dir entry name
  $command{'move'}<p/n>:<newpos>    move dir to new position in same list
  $command{'move'}<p/n>:<ln>\[:<np>\] move to pos <np> on diff. list named ln
  $command{'list'}                  display menu with of lists
  $command{'list'}:<listname>       select which list to display (current/archive)
  $command{'sort'}:p|n|v            sort list by Position (default), Name, Visit count,
  $command{'sort'}:l|c|d            by time of Last visit, time of Creation, Dir path
  $command{'undo'}                  undo last command
  $command{'redo'}                  redo - revert previously made undo
  $command{'help'}                  long help
  $command{'help'}:txt              overview text
  $command{'help'}:cmd              display list of commands
  <Enter>            exit

  commands for managing lists:

  <pos>              switch to dir list named on <pos>
  :<name>            switch to dir list with <name>
  $command{'add'}<listname>        create a new list
  $command{'delete'}<p/n>\             delete list (has to be empty)
  $command{'name'}<p/n>:<name>      rename dir list
EOH
    }
}


__END__

create list
delete list
rename list
neg indicies
