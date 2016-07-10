package Collectd::Plugins::ZFS;

use strict;
no strict "subs";

use Collectd qw (:plugin :types);

my %zpool;
my %zfs;
my $snap_count;

sub get_zpool_zfs_data
  {
  %zpool = {};
  %zfs = {};

  my $cmd = "zpool get -pH size,free,freeing,capacity,fragmentation";
  open(my $zpool, "-|", $cmd);
  my %zpool;
  while (my $line = <$zpool>)
    {
    chomp $line;
    my @data = split(/\s/, $line);
    $data[2] =~ s/\%//g;
    $zpool{$data[1]} = $data[2];
    }
  close $zpool;

  my $cmd = "zfs list -o mountpoint,compressratio,refcompressratio,used,available,usedbydataset,usedbysnapshots -p -t filesystem";
  open(my $zfs, "-|", $cmd);
  my %zfs;
  my $headers = <$zfs>;
  chomp $headers;
  my @headers = split(/\s+/, $headers);
  for (my $x = 0; $x < scalar(@headers); $x++)
    {
    $headers[$x] = lc($headers[$x]);
    }
  while (my $line = <$zfs>)
    {
    chomp $line;
    my @data = split(/\s+/, $line);
    $zfs{$data[0]} = {};
    for (my $x = 1; $x < scalar(@data); $x++)
      {
      if ($data[$x] =~ /^\d+$/)
        {
        $data[$x] = $data[$x];
        }
      $zfs{$data[0]}->{$headers[$x]} = $data[$x];
      }
    }
  close $zfs;

  my $cmd = "sudo zfs list -t snapshot";
  open(my $zfs , "-|", $cmd);
  while (<$zfs>) { $snap_count++; }
  close $zfs;

  return 1;
  }

sub snapshot_write
  {
  my $value = { 
    plugin => 'ZFS', 
    type => 'gauge',
    values => [ $snap_count],
    };

  plugin_dispatch_values ($value );
  return 1;
  }

plugin_register (TYPE_INIT, "ZFS", "get_zpool_zfs_data");
plugin_register (TYPE_READ, "ZFS", "snapshot_write");

1;
