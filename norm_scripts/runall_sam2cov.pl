if (@ARGV<3){
  die "usage: runall_sam2cov.pl <sample dirs> <loc> <fai file> [options]


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


$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
$norm_dir = $study_dir . "NORMALIZED_DATA";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_M_dir = "$finalsam_dir/MERGED";
$fai_file = $ARGV[2]; # fai file

open(INFILE, $ARGV[0]); # dirnames
while($line =  <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $dir;
    $id = s/Sample_//;
    $filename = "$final_M_dir/$id.FINAL.norm.sam";
    $prefix = $filename;
    $prefix =~ s/.sam//;
    $shfile = "C" . $id . ".sam2cov.sh";
    open(OUTFILE, ">$shdir/$shfile");
    print OUTFILE "/opt/rna_seq/scripts/sam2cov -s 1 -p $prefix $fai_file $filename"; # only fwd reads;star alignment
    close(OUTFILE);
    `bsub -o $logdir/$id.sam2cov.out -e $logdir/$id.sam2cov.err sh $shdir/$shfile`;
}
close(INFILE);


