#!/usr/bin/perl

use strict;
use Redis;
use Data::Dumper;
use Number::Bytes::Human;
use Time::Stopwatch;

tie my $timer, 'Time::Stopwatch';

my $debug = 0;
my $snap_count_interval = 300;
$| = 1;

while (1)
  {
  $timer = 0;
  my $cmd = "sudo zfs list -t snapshot";
  open(my $zfs , "-|", $cmd);
  my $snapshot_count = 0;
  while (<$zfs>) { $snapshot_count++; }
  close $zfs;
  print "PUTVAL jupiter/ZFS/zfs_snapshots-Snapshots interval=" . $snap_count_interval . " N:" . $snapshot_count . "\n";
  sleep $snap_count_interval;
  }

sub convert_human_readable_into_bytes
  {
  # humans are stupid.
  my $input = shift;

  my %factors = 
    (
    'K' => 2**10,
    'M' => 2**20,
    'G' => 2**30,
    'T' => 2**40,
    );
  $input =~ /([\.\d]+)([A-Z]?)/;
  my $quantity = $1;
  my $scale = $2;  
  if ($scale)
    {
    return int($quantity * $factors{$scale});
    }
  else
    {
    return $quantity;
    }
  }
