if(@ARGV<2) {
    die "Usage: perl runall_get_ribo_percents.pl <sample dirs> <loc> [option]

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

option:  -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";
}
$bsub = "false";
$qsub = "false";
$numargs = 0;
for ($i=2; $i<@ARGV; $i++){
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
$path = abs_path($0);
$path =~ s/runall_//;
$sampledirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$shfile = "$shdir/get_ribo_percents.sh";
open(OUT, ">$shfile");
print OUT "perl $path $sampledirs $LOC\n";
if ($bsub eq "true"){
    `bsub -q max_mem30 -o $logdir/getribopercents.out -e $logdir/getribopercents.err sh $shfile`;
}
if ($qsub eq "true"){
    `qsub -cwd -N getribopercents -o $logdir -e $logdir -l h_vmem=10G $shfile`;
}
