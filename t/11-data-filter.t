#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 11;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

my $class = 'App::Goto::Dir::Data::Filter';
use_ok( $class );


exit 0;
