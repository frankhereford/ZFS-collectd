#!/usr/bin/perl

use strict;
use Redis;

my $redis = Redis->new;

while (sleep 30)
  {
  my $cmd = "sudo zfs list -t snapshot";
  open(my $zfs , "-|", $cmd);
  my $snapshot_count = 0;
  while (<$zfs>) { $snapshot_count++; }
  close $zfs;
  $redis->set('snapshot_count' => $snapshot_count);
  }



