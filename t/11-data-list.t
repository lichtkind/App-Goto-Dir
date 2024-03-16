#!/usr/bin/perl -w
use v5.18;
use warnings;
use Test::More tests => 33;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::List';
use_ok( $class );
