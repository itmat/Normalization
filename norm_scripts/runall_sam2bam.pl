#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_sam2bam.pl <sample dirs> <loc> <sam file name> <fai file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<fai file> fai file (full path)

option:
 -pmacs : set this if you want to submit batch jobs to PMACS cluster (LSF).

 -pgfi : set this if you want to submit batch jobs to PGFI cluster (Sun Grid Engine).

 -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>:
        set this if you're not on PMACS (LSF) or PGFI (SGE) cluster.

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -h : print usage

";
if(@ARGV<4){
    die $USAGE;
}
$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";

for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-pmacs'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-q";
        $mem = "plus";
    }
    if ($ARGV[$i] eq '-pgfi'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
        $submit = $ARGV[$i+1];
        $jobname_option = $ARGV[$i+2];
        $request_memory_option = $ARGV[$i+3];
        $mem = $ARGV[$i+4];
        $i++;
        $i++;
        $i++;
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide <submit>, <jobname_option>, and <request_memory_option> <queue_name_for_6G>\n";
        }
        if ($submit eq "-pmacs" | $submit eq "-pgfi"){
            die "you have to specify how you want to submit batch jobs. choose -pmacs, -pgfi, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>.\n";
        }
    }
    if ($ARGV[$i] eq '-mem'){
        $option_found = "true";
        $new_mem = $ARGV[$i+1];
        $replace_mem = "true";
        $i++;
        if ($new_mem eq ""){
            die "please provide a queue name.\n";
        }
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -pmacs, -pgfi, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>.\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
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
    $jobname = "$study.sam2bam";
    $logname = "$logdir/sam2bam.$id";
    $norm_shfile = "$shdir/$id.sam2bam.norm.sh";
    $logname_norm = "$logdir/sam2bam.norm.$id";
    if (-e "$LOC/$line/$sam_name"){
	open(OUT, ">$shfile");
	print OUT "samtools view -bt $fai_file $LOC/$line/$sam_name > $LOC/$line/$bam_name\n";
	print OUT "rm $LOC/$line/$sam_name\n";
	close(OUT);
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
	if (-e "$final_M_dir/$id.FINAL.norm.sam"){
	    open(OUT2, ">$norm_shfile");
	    print OUT2 "samtools view -bt $fai_file $final_M_dir/$id.FINAL.norm.sam > $final_M_dir/$id.FINAL.norm.bam\n";
	    print OUT2 "rm $final_M_dir/$id.FINAL.norm.sam\n";
	    close(OUT2);
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
	}
	else{
	    if (-e "$final_U_dir/$id.FINAL.norm_u.sam"){
		open(OUT2, ">$norm_shfile");
		print OUT2 "samtools view -bt $fai_file $final_U_dir/$id.FINAL.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.bam\n";
		print OUT2 "rm $final_U_dir/$id.FINAL.norm_u.sam\n";
		close(OUT2);
		`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
	    }
	    if (-e "$final_NU_dir/$id.FINAL.norm_nu.sam"){
                open(OUT2, ">$norm_shfile");
                print OUT2 "samtools view -bt $fai_file $final_NU_dir/$id.FINAL.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.bam\n";
                print OUT2 "rm $final_NU_dir/$id.FINAL.norm_nu.sam\n";
                close(OUT2);
		`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
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

	
