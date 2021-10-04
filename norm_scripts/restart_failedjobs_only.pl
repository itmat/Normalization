#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl restart_failedjobs_only.pl <sample dirs> <loc> <errname> <queuename>

<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<errname> is the name of error log files (e.g. \"sam2mappingstats*err\")
          **make sure the name argument is inside the quotes**
<queuename> queue used 

[option]
-qlist '3G,6G,10G,15G,30G,45G,60G'

\n";
my $size = @ARGV;
if (@ARGV < 4){
    die $USAGE;
}
my @list;
my $qopt=0;
for(my $i=4;$i<@ARGV;$i++){
    my $option_rec = "false";
    if ($ARGV[$i] eq '-qlist'){
        $option_rec = "true";
        @list = split(",", $ARGV[$i+1]);
        $i++;
        $qopt++;
    }
    if ($option_rec eq 'false'){
        die "option \"$ARGV[$i]\" not recognized\n";
    }
}
if ($qopt == 0){
    die "Please provide -qlist '3G,6G,10G,15G,30G,45G,60G\n";
}
my $dirs = $ARGV[0];
my $LOC = $ARGV[1];
my $errname = $ARGV[2];
$LOC =~ s/\/$//;
my $qused = $ARGV[3];
my $to_print = $qused;
$qused =~ s/-mem//;
$qused =~ s/^\s+|\s+$//g;
my $nindex;
for(my $i=0;$i<@list;$i++){
    my $tmp = $list[$i];
    $tmp =~ s/^\s+|\s+$//g;
    if ($tmp eq $qused){
        $nindex = $i+1;
    }
}
if ($nindex >= @list){
    $nindex--;
}
#die "$qused\n$list[$nindex]\n";

my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $logdir = "$study_dir/logs";

$errname =~ s/\.\*.err$//;
$errname =~ s/\*.err$//;
$errname =~ s/\.\*err$//;
$errname =~ s/\*err$//;
my %RESTART;
open(IN, $dirs) or die "cannot find file $dirs\n";
while(my $line = <IN>){
    chomp($line);
    my $ofile = "$logdir/$errname*$line*out";
    my $efile = "$logdir/$errname*$line*err";
    my @og = glob($ofile);
    my @eg = glob($efile);
    if ((@og eq 0) || (@eg eq 0)){ # logfiles don't exist.
#	print "1: restart\n";
	$RESTART{$line} = 1;
	if (@og ne 0){
	    my $x = `rm $ofile`;
	}
	if (@eg ne 0){
	    my $y = `rm $efile`;
	}
    }
    elsif (@og != @eg){ # number of .out and .err files do not match
#	print "2: restart\n";
	$RESTART{$line} = 1;
	my $x = `rm $ofile`;
	my $y = `rm $efile`;
    }
    else{ 
	my $grep = `grep "got here" $ofile | grep -vc echo`;
	my $cnt = @og;
	if ($cnt == $grep){ # check "got here" - in all .out file
	    my $w = `wc -l $efile`;
	    my @r = split(/\n/, $w);
	    my $lastrow = $r[@r-1];
	    my @c = split(" ", $lastrow);
	    my $cnt = $c[0];
	    if ($cnt == 0){ #check .err - empty
#		print "3: skip\n";
		next;
	    }
	    else{ # err - not empty
#		print "4: restart\n";
		$RESTART{$line} = 1;
		my $x = `rm $ofile`;
		my $y = `rm $efile`;
	    }
	}
	else{ # "got here" not in all .out files
#	    print "5: restart\n";
            my $w = `wc -l $efile`;
            my @r = split(/\n/, $w);
            my $lastrow = $r[@r-1];
            my @c = split(" ", $lastrow);
            my $cnt = $c[0];
            if ($cnt == 0){ #check .err - empty
                 #increase mem
                 $to_print = "-mem $list[$nindex]";
            }
	    $RESTART{$line} = 1;
	    my $x = `rm $ofile`;		
	    my $y = `rm $efile`;
	}
    }
}
my $num_res = keys %RESTART;
my $resume_file = "$dirs.resume";
if ($num_res > 0){ 
    open(OUT, ">$resume_file");
    foreach my $sample (keys %RESTART){
	print OUT "$sample\n";
    }
}
else{ # restart all
    my $c = `cp $dirs $resume_file`;
    open(IN, $dirs) or die "cannot find file $dirs\n";
    while(my $line = <IN>){
	chomp($line);
	my $ofile = "$logdir/$errname*$line*out";
	my $efile = "$logdir/$errname*$line*err";
	my $x = `rm $ofile`;
	my $y = `rm $efile`;
    }
    close(IN);
}
print $to_print;
