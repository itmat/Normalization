if(@ARGV<4){
    die "usage: perl runall_sam2bam.pl <sample dirs> <loc> <sam file name> <fai file>

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<fai file> fai file (full path)

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
	print OUT "samtools sort $LOC/$line/$bam_name $LOC/$line/$sorted_bam\n";
	print OUT "samtools index $LOC/$line/$sorted_bam.bam\n";
	print OUT "rm $LOC/$line/$bam_name $LOC/$line/$sam_name\n";
	close(OUT);
	`bsub -q plus -o $logdir/$id.sam2bam.out -e $logdir/$id.sam2bam.err sh $shfile`;
	if (-e "$final_M_dir/$id.FINAL.norm.sam"){
	    open(OUT2, ">$norm_shfile");
	    print OUT2 "samtools view -bt $fai_file $final_M_dir/$id.FINAL.norm.sam > $final_M_dir/$id.FINAL.norm.bam\n";
	    print OUT2 "samtools sort $final_M_dir/$id.FINAL.norm.bam $final_M_dir/$id.FINAL.norm-sorted\n";
	    print OUT2 "samtools index $final_M_dir/$id.FINAL.norm-sorted.bam\n";
	    print OUT2 "rm $final_M_dir/$id.FINAL.norm.bam $final_M_dir/$id.FINAL.norm.sam\n";
	    close(OUT2);
	    `bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
	}
	else{
	    if (-e "$final_U_dir/$id.FINAL.norm_u.sam"){
		open(OUT2, ">$norm_shfile");
		print OUT2 "samtools view -bt $fai_file $final_U_dir/$id.FINAL.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.bam\n";
		print OUT2 "samtools sort $final_U_dir/$id.FINAL.norm_u.bam $final_U_dir/$id.FINAL.norm_u-sorted\n";
		print OUT2 "samtools index $final_U_dir/$id.FINAL.norm_u-sorted.bam\n";
		print OUT2 "rm $final_U_dir/$id.FINAL.norm_u.bam $final_U_dir/$id.FINAL.norm_u.sam\n";
		close(OUT2);
		`bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
	    }
	    if (-e "$final_NU_dir/$id.FINAL.norm_nu.sam"){
                open(OUT2, ">$norm_shfile");
                print OUT2 "samtools view -bt $fai_file $final_NU_dir/$id.FINAL.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.bam\n";
                print OUT2 "samtools sort $final_NU_dir/$id.FINAL.norm_nu.bam $final_NU_dir/$id.FINAL.norm_nu-sorted\n";
                print OUT2 "samtools index $final_NU_dir/$id.FINAL.norm_nu-sorted.bam\n";
                print OUT2 "rm $final_NU_dir/$id.FINAL.norm_nu.bam $final_NU_dir/$id.FINAL.norm_nu.sam\n";
                close(OUT2);
                `bsub -q plus -o $logdir/$id.norm.sam2bam.out -e $logdir/$id.norm.sam2bam.err sh $norm_shfile`;
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

	
