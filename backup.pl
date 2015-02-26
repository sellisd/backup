#!/usr/bin/perl
use warnings;
use strict;
use POSIX qw(strftime);
#TODO make link to the most recent backup for incremental
# using lots of modules (if available) aiming for portability in the near(?) future
use Module::Load::Conditional qw[can_load check_install requires];
use File::HomeDir;
use File::DirList;
use Getopt::Long;
use File::Path qw(make_path);
#use Sys::Hostname;

#default values
my $help;
my $drive =  '/media/dsellis/backupB/'; # path to backup drive
my $type = 'incremental';  # full/incremental
my $dry = 0;
my $usage = <<HERE;

Simple backup using rsync
usage ./backup.pl [OPTIONS]
where OPTIONS can be:
   -to:     path to backup directory (default: /media/dsellis/backubB/)
   -type:   full/incremental (default: incremental)
   -dry:    rsync --dry-run
   -help|?: this help screen

HERE
    
die $usage unless (GetOptions('help|?' => \$help,
			      'to=s'   => \$drive,
                              'type=s' => \$type,
                              'dry'    => \$dry
    ));

die $usage if $help;

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
make_path($to) unless -e $to;
my $cmdl = 'rsync ';
my $isDryRun;
if($dry){
  $isDryRun = ' --dry-run ';
}else{
  $isDryRun = ' ';
}
if ($type eq 'full'){
  $cmdl = $cmdl.$isDryRun.$excludeString.$deleteString.$rsyncParamsString.' '.$from.' '.$to;
}elsif($type eq 'incremental'){
  my $prevBackupDirs = File::DirList::list($drive.$hostname,'M',1,0);
#use Data::Dumper;
#print Dumper $prevBackupDirs->[0][13];die;
  $cmdl .= $isDryRun.$excludeString.$deleteString.$rsyncParamsString.' '.'--link-dest '.$drive.$hostname.'/'.$prevBackupDirs->[0][13].' '.$from.' '.$to;
}else{
  die "unknown type: ".$type;
}
print $cmdl,"\n";
system "$cmdl > $now.log"; #save the log file in the home directory?
