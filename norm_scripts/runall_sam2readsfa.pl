#!/usr/bin/env perl
if(@ARGV < 3) {
    die "Usage: perl runall_sam2readsfa.pl <sample dirs> <loc> <sam file name> [options]

<sample dirs> a file with the names of the sample directories with sam file (without paths)

<loc> is the path of the directory with the sample directories

<sam file name> is the name of the sam file 

option:  -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.


";
}

$bsub = "false";
$qsub = "false";
$numargs = 0;
for ($i=3; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-bsub'){
	$bsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-qsub'){
	$qsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}

use Cwd 'abs_path';
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir -p $shdir`;}
unless (-d $logdir){
    `mkdir -p $logdir`;}
$sam = $ARGV[2];
$path = abs_path($0);
$path =~ s/runall_//;
open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $line =~ s/\//_/g;
    $id = $line;
    $shfile = "$shdir/a" . $id . "runsam2fa.sh";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path $LOC/$dir/$sam $LOC/$dir/reads.fa\n";
    close(OUTFILE);
    if ($bsub eq "true"){
	`bsub -e $logdir/$id.sam2readsfa.err -o $logdir/$id.sam2readsfa.out sh $shfile`;
    }
    if ($qsub eq "true"){
	`qsub -cwd -N $dir.sam2readsfa -e $logidr -o $logdir $shfile`;
    }
}
close(INFILE);
