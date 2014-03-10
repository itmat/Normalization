if(@ARGV < 5) {
    die "usage: perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db> [option]

where
<sample dirs> is a file of sample dirs with alignment output
              without path, just the dir names
<loc> is the path to the directory that has the sample dirs
<samfile> is the name of the sam file (without path)
<blast dir> is the blast dir (full path)
<db> database (full path)

option:  -bsub : set this if you want to submit batch jobs to LSF. 
 
         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";

}

$bsub = "false";
$qsub = "false";
$numargs = 0;
for ($i=5; $i<@ARGV; $i++){
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
open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";  
$LOC = $ARGV[1];  
$LOC =~ s/\/$//;
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$path = abs_path($0);
$path =~ s/runall_//;
$samfile = $ARGV[2]; # the name of the sam file (without path)
$blastdir = $ARGV[3];
$db = $ARGV[4];

while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $line =~ s/Sample_//;
    $line =~ s/\//_/g;
    $id = $line;
    $shfile = "$shdir/a" . $id . "runblast.sh";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path $dir $LOC $samfile $blastdir $db\n";
    close(OUTFILE);
    if ($bsub eq "true"){
	`bsub -q plus -e $logdir/$id.runblast.err -o $logdir/$id.runblast.out sh $shfile`;
    }
    if ($qsub eq "true"){
	`qsub -N $dir.runblast -e $logdir -o $logdir -l h_vmem=6G $shfile`;
    }
}
close(INFILE);
