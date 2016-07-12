package Collectd::Plugins::ZFS;

use strict;
no strict "subs";
use Data::Dumper;
use Redis;

use Collectd qw (:all);

my $redis = Redis->new;

my $host = `hostname -f`;
chomp $host;

sub snapshot_read
  {
  #my $cmd = "sudo zfs list -t snapshot";
  #open(my $zfs , "-|", $cmd);
  #my $snapshot_count = 0;
  #while (<$zfs>) { $snapshot_count++; }
  #close $zfs;

  # This just comes out of reddis from a daemon now. It's slow under heavy disk load.
  my $snapshot_count = $redis->get('snapshot_count');

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
  my $cmd = "zpool get -pH size,allocated,free,freeing,capacity,fragmentation";
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

  #my $size = 
    #{
    #plugin => 'ZFS',
    #type => 'zpool_space',
    #time => time,
    #type_instance => 'Total Size',
    #interval => plugin_get_interval(),
    #host => $host,
    #values => [ $zpool{'size'}],
    #};
  #plugin_dispatch_values ($size);

  my $allocated = 
    {
    plugin => 'ZFS',
    type => 'zpool_space',
    time => time,
    type_instance => 'Allocated Space',
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'allocated'}],
    };
  plugin_dispatch_values ($allocated);

  my $free = 
    {
    plugin => 'ZFS',
    type => 'zpool_space',
    time => time,
    type_instance => 'Free Space',
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'free'}],
    };
  plugin_dispatch_values ($free);

  my $freeing = 
    {
    plugin => 'ZFS',
    type => 'zpool_space',
    type_instance => 'Space Being Freed',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'freeing'}],
    };
  plugin_dispatch_values ($freeing);

  my $capacity = 
    {
    plugin => 'ZFS',
    type => 'zpool_percentage',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'capacity'}],
    type_instance => '% Capacity',
    };
  plugin_dispatch_values ($capacity);

  my $fragmentation = 
    {
    plugin => 'ZFS',
    type => 'zpool_percentage',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [ $zpool{'fragmentation'}],
    type_instance => '% Fragmentation',
    };
  plugin_dispatch_values ($fragmentation);

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
      $data[$x] =~ s/[^\.\d]//g;
      $zfs{$data[0]}->{$headers[$x]} = $data[$x];
      }
    }
  close $zfs;  

  my $totalsnap = 0;
  foreach my $filesystem (keys(%zfs))
    {

    # maybe work in available here into the zpool space graph for the first iteration? 

    my $compressratio = 
      {
      plugin => 'ZFS',
      #plugin_instance => $filesystem, # for when you want a jillion graphs
      type_instance => $filesystem, # for when you want a jillion lines on one graph. This could go in the flipping docs y'all.
      type => 'zfs_compression_ratio',
      time => time,
      interval => plugin_get_interval(),
      host => $host,
      values => [$zfs{$filesystem}->{'ratio'}],
      };    
    plugin_dispatch_values ($compressratio); 

    my $zfs_filesystem_space_used = 
      {
      plugin => 'ZFS',
      type_instance => $filesystem,
      type => 'zfs_filesystem_space_used',
      time => time,
      interval => plugin_get_interval(),
      host => $host,
      values => [$zfs{$filesystem}->{'usedds'}], # 'used' includes decsendents, the 'ds' means just this data set
      };    
    plugin_dispatch_values ($zfs_filesystem_space_used); 

    my $zfs_filesystem_snap_space = 
      {
      plugin => 'ZFS',
      type_instance => $filesystem,
      type => 'zfs_filesystem_snap_space_used',
      time => time,
      interval => plugin_get_interval(),
      host => $host,
      values => [$zfs{$filesystem}->{'usedsnap'}],
      };    
    plugin_dispatch_values ($zfs_filesystem_snap_space); 

    $totalsnap += $zfs{$filesystem}->{'usedsnap'};
    }

  my $used_snap = 
    {
    plugin => 'ZFS',
    type => 'zpool_space',
    type_instance => 'Snapshot Space Used',
    time => time,
    interval => plugin_get_interval(),
    host => $host,
    values => [$totalsnap],
    };
  plugin_dispatch_values ($used_snap); 
  }

sub read
  {
  snapshot_read;
  zpool_read;
  zfs_read;
  return 1;
  }

Collectd::plugin_register(Collectd::TYPE_READ, "ZFS", "read");

1;
