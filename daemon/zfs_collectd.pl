#!/usr/bin/perl

use strict;
use Redis;
use Data::Dumper;
use Number::Bytes::Human;
use Time::Stopwatch;

tie my $timer, 'Time::Stopwatch';

my $debug = 0;
my $operations_interval = 10;
my $snap_count_interval = $operations_interval * 3; # inner loop to operations interval, so make this a multiple of the operations interval
$| = 1;

my $cmd = "sudo zpool iostat -y " . $operations_interval;
open(my $zpool, "-|", $cmd);
<$zpool>; <$zpool>; <$zpool>;
#print <$zpool>; print <$zpool>; print <$zpool>;
#print "\n";

#'pool', 'alloc', 'free', 'read', 'write', 'read', 'write'
#0       1         2       3       4       5       6
while (my $data = <$zpool>)
  {
  #chomp $data;
  my @data = split(/\s+/, $data);
  next if $data[0] =~ /^-+$/;
  #print Dumper \@data, "\n";
  my $ops_read_key = $data[0] . '-' . 'ops-read';
  my $ops_write_key = $data[0] . '-' . 'ops-write';
  my $bw_read_key = $data[0] . '-' . 'bw-read';
  my $bw_write_key = $data[0] . '-' . 'bw-write';

  print $ops_read_key, " => ", convert_human_readable_into_bytes($data[3]), "\n" if ($debug);
  print $ops_write_key, " => ", convert_human_readable_into_bytes($data[4]), "\n" if ($debug);
  print $bw_read_key, " => ", convert_human_readable_into_bytes($data[5]), "\n" if ($debug);
  print $bw_write_key, " => ", convert_human_readable_into_bytes($data[6]), "\n" if ($debug);

  print "PUTVAL mybutterhalf/ZFS/zfs_ops_rate-Pool_Read_Operations interval=" . $operations_interval . " N:" . convert_human_readable_into_bytes($data[3])  . "\n";
  print "PUTVAL mybutterhalf/ZFS/zfs_ops_rate-Pool_Write_Operations interval=" . $operations_interval . " N:" . convert_human_readable_into_bytes($data[4])  . "\n";
  print "PUTVAL mybutterhalf/ZFS/zfs_bw_rate-Pool_Read_Bandwidth interval=" . $operations_interval . " N:" . convert_human_readable_into_bytes($data[5])  . "\n";
  print "PUTVAL mybutterhalf/ZFS/zfs_bw_rate-Pool_Write_Bandwidth interval=" . $operations_interval . " N:" . convert_human_readable_into_bytes($data[6])  . "\n";

  #$redis->set($ops_read_key => convert_human_readable_into_bytes($data[3]));
  #$redis->set($ops_write_key => convert_human_readable_into_bytes($data[4]));
  #$redis->set($bw_read_key => convert_human_readable_into_bytes($data[5]));
  #$redis->set($bw_write_key => convert_human_readable_into_bytes($data[6]));

  if ($timer > $snap_count_interval)
    {
    $timer = 0;
    my $cmd = "sudo zfs list -t snapshot";
    open(my $zfs , "-|", $cmd);
    my $snapshot_count = 0;
    while (<$zfs>) { $snapshot_count++; }
    close $zfs;
    print "PUTVAL mybutterhalf/ZFS/zfs_snapshots-Snapshots interval=" . $snap_count_interval . " N:" . $snapshot_count . "\n";
    }
  }
close $zpool;

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
