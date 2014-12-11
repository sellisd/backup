#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;


my $drive; # path to backup drive
my $type;  # full/incremental
my $timeType; # use local time or GMT
my $hostname; #name of computer

my $time = $localtime(); 
my @exclude = qw #
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
#

