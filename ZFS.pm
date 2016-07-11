package Collectd::Plugins::ZFS;

use strict;
no strict "subs";
use Data::Dumper;
use Redis;

use Collectd qw (:all);

my $redis = Redis->new;

sub snapshot_read
  {
  #my $cmd = "sudo zfs list -t snapshot";
  #open(my $zfs , "-|", $cmd);
  #my $snapshot_count = 0;
  #while (<$zfs>) { $snapshot_count++; }
  #close $zfs;

  my $snapshot_count = $redis->get('snapshot_count');

  my $host = `hostname -f`;
  chomp $host;

  my $data = 
    {
    plugin => 'ZFS',
    type => 'zfs_snapshots',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [ $snapshot_count ],
    };

  #Collectd::plugin_log(Collectd::LOG_WARNING, Dumper $data);
  plugin_dispatch_values ($data);
  return 1;
  }

sub zpool_read
  {
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


  # Fighting with this perl "API" to do some of the more complex stuf.. 

  my $host = `hostname -f`;
  chomp $host;

  #my $data = 
    #{
    #plugin => 'ZFS',
    #type => 'zpool_size',
    #time => time,
    #interval => plugin_get_interval(),
    #host => $host,
    #values => [$zpool{'size'}, $zpool{'free'}],
    #};
  #plugin_dispatch_values ($data);

  #my $data = 
    #{
    #plugin => 'ZFS',
    ##type => 'zpool_free',
    #time => time,
    #interval => plugin_get_interval(),
    #host => $host,
    #values => [ $zpool{'free'}],
    #};

  my $freeing = 
    {
    plugin => 'ZFS',
    type => 'zpool_freeing',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'freeing'}],
    };

  plugin_dispatch_values ($freeing);

  return 1;
  }



sub zfs_read
  {
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
  }

sub read
  {
  snapshot_read();
  zpool_read;
  return 1;
  }

Collectd::plugin_register(Collectd::TYPE_READ, "ZFS", "read");

1;
