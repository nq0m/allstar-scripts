#!/usr/bin/perl
#
# say_wx.pl  - Jeremy Utley, NQ0M 06/11/2017
#
# Perl program to say the weather conditions using the AllStar
# built in sound functions.  Adapted from the default saytime.pl 
# script by D. Crompton, WA3DSP, included with the HamVOIP
# distribution.
#
# Call this program from a cron job and/or rpt.conf when you want to 
# hear the weather on your local node
#
# Example Cron job to say the time on the hour every hour:
#   Change directory and times to your liking
#
# 00 0-23 * * * cd /etc/asterisk/wa3dsp; perl say_wx.pl <wxid> <node> > /dev/null
#
# Note in this program all sound files must be .gsm
# All combined soundfiile formats need to be the same. 
# This could be changed if necessary. To use this with the
# stock Acid release you will need to convert a couple
# of the ulaw files in the /sounds/rpt directory to .gsm
# using sox or another conversion program and place them
# in the sounds directory for use by this program.
# The good-xxx.gsm files and the-time-is.gsm were created
# from ulaw files in the /sounds/rpt directory.
# An example sox command to do this is -
#
#  sox -t ul -r 8000 /var/lib/asterisk/sounds/rpt/thetimeis.ulaw /var/lib/asterisk/sounds/the-time-is.gsm


# For weather condtions and temperature Use:  saytime <locationID> <node>
# Location ID is either your zipcode or nearest airport three letter designator,
# or WUnderground id in the form of w-xxxxxxxx
# This REQUIRES the /usr/local/sbin/weather.sh script to run

use strict;
use warnings;
#
select (STDOUT);
$| = 1;
select (STDERR);
$| = 1;
#
# Replace with your output directory
my $outdir = "/tmp";
#
my $base = "/var/lib/asterisk/sounds";
my $FNAME,my $error,my $mynode,my $wx,my $wxid;
my @proglist,my @list;
my $localwxtemp10,my $localwxtemp1;
#
# command-line args
my $num_args = $#ARGV + 1;
# This script requires 2 arguments, arg1 is the Location ID, arg2 is the node number

if ($num_args == 2) {
    $wxid = ($ARGV[0]); 
    $mynode=$ARGV[1];
    $error=0;
} else {
    $error=1;
}

if ($error == 1) {
  print "\nUsage: say_wx.pl [<locationid>] nodenumber\n";
  exit;
}

my $localwxtemp="";

if (! -f "/usr/local/sbin/weather.sh" ) {
     exit;
}


  @proglist = ("/usr/local/sbin/weather.sh " . $wxid);
  system(@proglist);

  if (-f "$outdir/temperature") { 
    open(my $fh, '<', "$outdir/temperature") or die "cannot open file";
    {
        local $/;
        $localwxtemp = <$fh>;
    }
    close($fh);
  } else {
    $localwxtemp="";
  }

#

$FNAME = $base . "/silence/1.gsm ";

if (-e "$outdir/condition.gsm") {
    $FNAME = $FNAME . $base . "/weather.gsm ";
    $FNAME = $FNAME . $base . "/conditions.gsm ";
    $FNAME = $FNAME . "$outdir/condition.gsm ";
}
if ($localwxtemp ne "" ) {
    $FNAME = $FNAME . $base . "/wx/temperature.gsm ";

    if ($localwxtemp < -1 ) {
        $FNAME = $FNAME . $base . "/digits/minus.gsm ";
        $localwxtemp=int(abs($localwxtemp));
    } else {
        $localwxtemp=int($localwxtemp);
    }

    if ($localwxtemp > 100) {
        $FNAME = $FNAME . $base . "/digits/" . "1" . ".gsm ";
        $FNAME = $FNAME . $base . "/digits/" . "hundred" . ".gsm ";
        $localwxtemp=($localwxtemp-100);
    }

    if ($localwxtemp < 20) {
        $FNAME = $FNAME . $base . "/digits/" . $localwxtemp . ".gsm ";
    } else {
        $localwxtemp10 = substr ($localwxtemp,0,1) . "0";
        $FNAME = $FNAME . $base . "/digits/" . $localwxtemp10 . ".gsm ";
        $localwxtemp1 = substr ($localwxtemp,1,1);
        if ($localwxtemp1 > 0) {
          $FNAME = $FNAME . $base . "/digits/" . $localwxtemp1 . ".gsm ";
        }
    }
    $FNAME = $FNAME . $base . "/degrees.gsm ";
 }

#
# Following lines concatenate all of the files to one output file
#
@proglist = ("cat " . $FNAME . " > " . $outdir . "/current-wx.gsm");
system(@proglist);
#
# Following lines process the output file with sox to lower the volume
# negative numbers lower than -1 reduce the volume - see Sox man page
# Other processing could be done if necessary
#
# REMOVED V1.5 - use telemetry levels
#
#@proglist = ("nice -19 sox --temp /tmp " . $outdir . "/temp.gsm " . $outdir . "/current-time.gsm vol -0.35");
#system(@proglist);
#
# Say the time on the local node
#
@proglist = ("/usr/sbin/asterisk -rx \"rpt localplay " . $mynode . " " . $outdir . "/current-wx\"");
system(@proglist);

# end of say_wx.pl

