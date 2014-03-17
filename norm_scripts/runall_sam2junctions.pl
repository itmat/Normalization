if(@ARGV<4) {
    die "usage: runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample directories
<genes> is the RUM gene info file (with full path)
<genome> is the RUM genome sequene fasta file (with full path)

option:
 -samfilename <s> : set this to create junctions files using unfiltered aligned samfile.
                    <s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam)
                    and all sam files in each sample directory should have the same name.

 -u  :  set this if you want to return only unique junctions, otherwise by default
         it will return merged(unique+non-unique) junctions.

 -nu :  set this if you want to return only non-unique junctions, otherwise by default
         it will return merged(unique+non-unique) junctions.

 -bsub : set this if you want to submit batch jobs to LSF.

 -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_sam2junctions.pl//;
$U = "true";
$NU = "true";
$numargs = 0;
$option_found = "false";
$bsub = "false";
$qsub = "false";
$numargs_b = 0;
$samfilename = "false";
for($i=4; $i<@ARGV; $i++) {
    $option_found = "false";
    if ($ARGV[$i] eq '-samfilename'){
	$option_found = "true";
	$samname = $ARGV[$i+1];
	$i++;
	$samfilename = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-bsub'){
	$bsub = "true";
	$numargs_b++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-qsub'){
	$qsub = "true";
	$numargs_b++;
	$option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu. 
";
}
if($numargs_b ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}

open(INFILE, $ARGV[0]);
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
$norm_dir = $study_dir . "NORMALIZED_DATA";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";
$junctions_dir = "$norm_dir/Junctions";

$genes = $ARGV[2];
$genome = $ARGV[3];
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    if ($samfilename eq "true"){
	$final_dir = "$LOC/$dir";
	$filename = $samname;
	$junctions_dir = "$LOC/$dir";
    }
    else {
	unless (-d $junctions_dir){
	    `mkdir $junctions_dir`;
	}
	if ($numargs eq "0"){
	    $final_dir = $final_M_dir;
	    $filename = "$id.FINAL.norm.sam";
	}
	else{
	    if ($U eq "true"){
		$final_dir = $final_U_dir;
		$filename ="$id.FINAL.norm_u.sam";
	    }
	    if ($NU eq "true"){
		$final_dir = $final_NU_dir;
		$filename = "$id.FINAL.norm_nu.sam";
	    }
	}
    }
    $shfile = "J" . $id . $filename . ".sh";
    $outfile1 = $filename;
    $outfile1 =~ s/.sam/_junctions_all.rum/;
    $outfile2 = $filename;
    $outfile2 =~ s/.sam/_junctions_all.bed/;
    $outfile3 = $filename;
    $outfile3 =~ s/.sam/_junctions_hq.bed/;
    open(OUTFILE, ">$shdir/$shfile");
    print OUTFILE "perl $path/rum-2.0.5_05/bin/make_RUM_junctions_file.pl --genes $genes --sam-in $final_dir/$filename --genome $genome --all-rum-out $junctions_dir/$outfile1 --all-bed-out $junctions_dir/$outfile2 --high-bed-out $junctions_dir/$outfile3 -faok\n";
    close(OUTFILE);
    if($bsub eq "true"){
	`bsub -o $logdir/$id.sam2junctions.out -e $logdir/$id.sam2junctions.err sh $shdir/$shfile`;
    }
    if ($qsub eq "true"){
	`qsub -cwd -N $dir.sam2junctions -o $logdir -e $logdir $shdir/$shfile`;
    }
}
close(INFILE);
