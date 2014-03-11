if(@ARGV<4){
    die "usage: perl runall_sam2bam.pl <sample dirs> <loc> <sam file name> <fai file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<fai file> fai file (full path)

option:  -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.


";
}
$bsub = "false";
$qsub = "false";
$numargs = 0;
for ($i=4; $i<@ARGV; $i++){
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
$size = @fields;
$last_dir = $fields[@size-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
$norm_dir = $study_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";

$sam_name = $ARGV[2];
$bam_name = $sam_name;
$bam_name =~ s/.sam/.bam/;
$sorted_bam = $bam_name;
$sorted_bam =~ s/.bam/.sorted/;
$fai_file = $ARGV[3];

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $shfile = "$shdir/$id.sam2bam.sh";
    $norm_shfile = "$shdir/$id.sam2bam.norm.sh";
    if (-e "$LOC/$line/$sam_name"){
	open(OUT, ">$shfile");
	print OUT "samtools view -bt $fai_file $LOC/$line/$sam_name > $LOC/$line/$bam_name\n";
	print OUT "rm $LOC/$line/$sam_name\n";
	close(OUT);
	if ($bsub eq "true"){
	    `bsub -q plus -o $logdir/$id.sam2bam.out -e $logdir/$id.sam2bam.err sh $shfile`;
	}
	if ($qsub eq "true"){
	    `qsub -N $dir.sam2bam -o $logdir -e $logdir -l h_vmem=6G $shfile`;
	}
	if (-e "$final_M_dir/$id.FINAL.norm.sam"){
	    open(OUT2, ">$norm_shfile");
	    print OUT2 "samtools view -bt $fai_file $final_M_dir/$id.FINAL.norm.sam > $final_M_dir/$id.FINAL.norm.bam\n";
	    print OUT2 "rm $final_M_dir/$id.FINAL.norm.sam\n";
	    close(OUT2);
	    if ($bsub eq "true"){
		`bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
	    }
	    if ($qsub eq "true"){
		`qsub -N $dir.norm.sam2bam -o $logdir -e $logdir -l h_vmem=6G $norm_shfile`;
	    }
	}
	else{
	    if (-e "$final_U_dir/$id.FINAL.norm_u.sam"){
		open(OUT2, ">$norm_shfile");
		print OUT2 "samtools view -bt $fai_file $final_U_dir/$id.FINAL.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.bam\n";
		print OUT2 "rm $final_U_dir/$id.FINAL.norm_u.sam\n";
		close(OUT2);
		if ($bsub eq "true"){
		    `bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
		}
		if ($qsub eq "true"){
		    `qsub -N $dir.norm.sam2bam -o $logdir -e $logdir -l h_vmem=6G $norm_shfile`;
		}
	    }
	    if (-e "$final_NU_dir/$id.FINAL.norm_nu.sam"){
                open(OUT2, ">$norm_shfile");
                print OUT2 "samtools view -bt $fai_file $final_NU_dir/$id.FINAL.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.bam\n";
                print OUT2 "rm $final_NU_dir/$id.FINAL.norm_nu.sam\n";
                close(OUT2);
		if ($bsub eq "true"){
		    `bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
		}
		if ($qsub eq "true"){
		    `qsub -N $dir.norm.sam2bam -o $logdir -e $logdir -l h_vmem=6G $norm_shfile`;
		}
            }
	    else{
		print STDERR "ERROR: normalized sam file \"$final_M_dir/$id.FINAL.norm.sam\", \"$final_U_dir/$id.FINAL.norm_u.sam\", or \"$final_NU_dir/$id.FINAL.norm_nu.sam\" does not exist. Please check the input samfile name/path\n\n";
	    }
	}
    }
    else{
	print STDERR "ERROR: file \"$LOC/$line/$sam_name\" doesn't exist. please check the input samfile name/path\n\n.";
    }

}

	
