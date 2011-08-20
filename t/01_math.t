#! /usr/bin/perl
use Modern::Perl;
use autodie;
use Perlude;
use Perlude::Stuff ':math';
use Test::More 'no_plan';

my ( $got, $expected );

$got       = sum unfold 0..3;
$expected  = 6;
is $got, $expected, "sum";

$got       = sum product unfold 0..3;
$expected  = 0;
is ( $got, $expected, "product knows 0" );

# $got       = sum product unfold 1..3;
# $expected  = 6;
# is ( $got, $expected, "product" );
