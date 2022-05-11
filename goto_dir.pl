#!/usr/bin/perl
use v5.18;
use lib 'lib';
use warnings;
no warnings  qw/experimental::smartmatch/;
use Benchmark;
use Cwd;
use File::Spec;
use FindBin;
use YAML;

my $PROGRAM     = 'App::Goto::Dir';
my $VERSION     =  0.8;
my $config_file = 'goto_dir_config.yml';

my $t = Benchmark->new();
our $cwd = Cwd::cwd();
chdir $FindBin::Bin;
die "config file $config_file not found" unless -r $config_file;
(my $config) = YAML::LoadFile( $config_file );


