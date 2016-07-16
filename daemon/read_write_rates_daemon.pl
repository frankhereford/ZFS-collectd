#!/usr/bin/perl

use strict;
use Redis;
use Data::Dumper;
use Number::Bytes::Human;

my $debug = 0;

my $redis = Redis->new;

my $cmd = "zpool iostat -y 10";
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
  #print Dumper \@data, "\n";
  #$redis->set('snapshot_count' => $snapshot_count);
  my $ops_read_key = $data[0] . '-' . 'ops-read';
  my $ops_write_key = $data[0] . '-' . 'ops-write';
  my $bw_read_key = $data[0] . '-' . 'bw-read';
  my $bw_write_key = $data[0] . '-' . 'bw-write';

  print $ops_read_key, " => ", convert_human_readable_into_bytes($data[3]), "\n" if ($debug);
  print $ops_write_key, " => ", convert_human_readable_into_bytes($data[4]), "\n" if ($debug);
  print $bw_read_key, " => ", convert_human_readable_into_bytes($data[5]), "\n" if ($debug);
  print $bw_write_key, " => ", convert_human_readable_into_bytes($data[6]), "\n" if ($debug);

  $redis->set($ops_read_key => convert_human_readable_into_bytes($data[3]));
  $redis->set($ops_write_key => convert_human_readable_into_bytes($data[4]));
  $redis->set($bw_read_key => convert_human_readable_into_bytes($data[5]));
  $redis->set($bw_write_key => convert_human_readable_into_bytes($data[6]));

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