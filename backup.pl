#!/usr/bin/perl
use warnings;
use strict;
use POSIX qw(strftime);

# using lots of modules (if available) aiming for portability in the near(?) future
use Module::Load::Conditional qw[can_load check_install requires];
use File::HomeDir;
use File::DirList;
use Getopt::Long;
#use Sys::Hostname;

my $drive =  '/media/dsellis/backupB/'; # path to backup drive
my $type = 'incremental';  # full/incremental
my $timeType; # use local time or GMT
#my $hostname = hostname(); #name of computer
my $hostname = `hostname`;
chomp $hostname;
my $from = File::HomeDir->my_home.'/';
my $mostRecentBackup;
(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) = localtime();
$year +=1900;
$mon +=1;
my $now = sprintf("%04d-%02d-%02d.%02d:%02d:%02d", $year,$mon,$mday,$hour, $min, $sec);

#TODO move the excludes to a configuration file
my @exclude = qw#
Trash
.Thumbnails
.cache
.mozilla/firefox/*/Cache
.gvfs
backup
Desktop
Dropbox
Downloads
WualaDrive
#;

my $excludeString = '';
foreach my $exclude (@exclude){
  $excludeString .= ' --exclude "'.$exclude.'" ';
}
my $deleteString = ' --delete ';
my $rsyncParamsString = ' -avzh ';
my $to = $drive.$hostname.'/'.$now.'/';
my $cmdl = 'rsync ';
if ($type eq 'full'){
  $cmdl = $cmdl.$excludeString.$deleteString.$rsyncParamsString.' '.$from.' '.$to;
}elsif($type eq 'incremental'){
  my $prevBackupDirs = File::DirList::list($drive.$hostname,'M',1,0);
#use Data::Dumper;
#print Dumper $prevBackupDirs->[0][13];die;
  $cmdl .= $excludeString.$deleteString.$rsyncParamsString.' '.'--link-dest '.$drive.$hostname.'/'.$prevBackupDirs->[0][13].' '.$from.' '.$to;
}else{
  die;
}
print $cmdl,"\n";
system "$cmdl > $now.log"; #save the log file in the home directory?
