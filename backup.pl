#!/usr/bin/perl
use warnings;
use strict;
use POSIX qw(strftime);
#TODO make link to the most recent backup for incremental
# add option -info PROGRESS for progress
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
my $from = File::HomeDir->my_home.'/';

my $usage = <<HERE;

Simple backup using rsync
usage ./backup.pl [OPTIONS]
where OPTIONS can be:
   -to:     path to backup directory (default: /media/dsellis/backubB/)
   -type:   full/incremental (default: incremental)
   -dry:    rsync --dry-run
   -from:   source (by default home directory)
   -help|?: this help screen

HERE
    
die $usage unless (GetOptions('help|?' => \$help,
			      'to=s'   => \$drive,
                              'type=s' => \$type,
                              'dry'    => \$dry,
			      'from:s'   => \$from
    ));

die $usage if $help;

my $timeType; # use local time or GMT
#my $hostname = hostname(); #name of computer
my $hostname = `hostname`;
chomp $hostname;
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
data/overdominance
#;

my $excludeString = '';
foreach my $exclude (@exclude){
  $excludeString .= ' --exclude "'.$exclude.'" ';
}
my $deleteString = ' --delete ';
my $rsyncParamsString = ' -avzh ';
my $to = $drive.$hostname.'/'.$now.'/';
make_path($to) unless -e $to;

my $mostRecentBackup = $drive.$hostname.'/mostRecent';

if ($dry){
# do nothing
}else{
    if(-e $mostRecentBackup){ # if link is present
        #use it and replace it with the new one
        system 'ln -s '.$to.' '.$mostRecentBackup;
    }else{ # if not present
        if($type eq 'full'){
            # create new link
            system 'ln -s '.$to.' '.$mostRecentBackup;
        }elsif($type eq 'incremental'){
	    die "Cannot do incremental backup without previous ones!";
        }
    }
}
#die $to;
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
#  my $prevBackupDirs = $mostRecentBackup;
#use Data::Dumper;
#print Dumper $prevBackupDirs;die;
  $cmdl .= $isDryRun.$excludeString.$deleteString.$rsyncParamsString.' '.'--link-dest '.$mostRecentBackup.' '.$from.' '.$to;
}else{
  die "unknown type: ".$type;
}
print $cmdl,"\n";
system "$cmdl > $now.log"; #save the log file in the home directory?

# check for any space issues
print `df -h`;
