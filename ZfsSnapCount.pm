package Collectd::Plugins::ZfsSnapCount;

use strict;
no strict "subs";

use Collectd qw (:plugin :types);

sub snapshot_read
  {
  my $vl = { plugin => 'zfs_snapshot_count', type => 'gauge' };
  my $cmd = "sudo zfs list -t snapshot";
  open(my $zfs , "-|", $cmd);
  my $snapshot_count = 0;
  while (<$zfs>) { $snapshot_count++; }
  close $zfs;
  #print "Snap count: ", $snapshot_count, "\n";

  $vl->{'values'} = [ $snapshot_count ];
  plugin_dispatch_values ($vl);
  return 1;
  }

#sub snapshot_write
  #{
  #my ($type, $ds, $vl) = @_;
  #for (my $i = 0; $i < scalar (@$ds); ++$i) 
    #{
    ##print "$vl->{'plugin'} ($vl->{'type'}): $vl->{'values'}->[$i]\n";
    #}
  #return 1;
  #}

#sub snapshot_match
  #{
  #my ($ds, $vl, $meta, $user_data) = @_;
  #if (matches($ds, $vl)) 
    #{
    #return FC_MATCH_MATCHES;
    #}
  #else 
    #{
    #return FC_MATCH_NO_MATCH;
    #}
  #}

sub snapshot_log
  {
  return 1
  }

plugin_register (TYPE_LOG, "zfs_snapshot_count", "snapshot_log");
plugin_register (TYPE_READ, "zfs_snapshot_count", "snapshot_read");
#plugin_register (TYPE_WRITE, "zfs_snapshot_count", "snapshot_write");
#fc_register (FC_MATCH, "zfs_snapshot_count", "snapshot_match");

1;
