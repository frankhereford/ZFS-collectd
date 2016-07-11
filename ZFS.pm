package Collectd::Plugins::ZFS;

use strict;
no strict "subs";
use Data::Dumper;

use Collectd qw (:all);

sub snapshot_read
  {
  my $cmd = "sudo zfs list -t snapshot";
  open(my $zfs , "-|", $cmd);
  my $snapshot_count = 0;
  while (<$zfs>) { $snapshot_count++; }
  close $zfs;

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

  #my $host = `hostname -f`;
  #chomp $host;

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

  #plugin_dispatch_values ($data);

  return 1;
  }


sub read
  {
  snapshot_read();
  zpool_read;
  return 1;
  }

Collectd::plugin_register(Collectd::TYPE_READ, "ZFS", "read");

1;
