#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_compress.pl <sample dirs> <loc> <sam file name> <fai file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<fai file> fai file (full path)

option:
 -dont_cov : set this if you DO NOT want to gzip the coverage files (By default, it will gzip the coverage files).

 -dont_bam : set this if you DO NOT convert SAM to bam (By default, it will convert sam to bam).

 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

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
$gzip_cov = 'true';
$sam2bam = 'true';
$njobs = 200;
for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-dont_bam'){
	$option_found = 'true';
	$sam2bam = 'false';
    }
    if ($ARGV[$i] eq '-dont_cov'){
	$option_found = 'true';
	$gzip_cov = 'false';
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-q";
        $mem = "plus";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
	$argv_all = $ARGV[$i+1];
        @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_6G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<request_memory_option> ,<queue_name_for_6G>,<status>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_6G>,<status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
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
$cov_dir = "$norm_dir/COV/";

$sam_name = $ARGV[2];
$bam_name = $sam_name;
$bam_name =~ s/.sam/.bam/;
$sorted_bam = $bam_name;
$sorted_bam =~ s/.bam/.sorted/;
$fai_file = $ARGV[3];
if ($sam2bam eq 'true'){
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
	    print OUT "echo \"got here \"\n";
	    close(OUT);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
	    if (-e "$final_M_dir/$id.FINAL.norm.sam"){
		open(OUT2, ">$norm_shfile");
		print OUT2 "samtools view -bt $fai_file $final_M_dir/$id.FINAL.norm.sam > $final_M_dir/$id.FINAL.norm.bam \n";
		print OUT2 "rm $final_M_dir/$id.FINAL.norm.sam\n";
		print OUT2 "echo \"got here \"\n";
		close(OUT2);
		while (qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
	    }
	    else{
		if (-e "$final_U_dir/$id.FINAL.norm_u.sam"){
		    open(OUT2, ">$norm_shfile");
		    print OUT2 "samtools view -bt $fai_file $final_U_dir/$id.FINAL.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.bam \n";
		    print OUT2 "rm $final_U_dir/$id.FINAL.norm_u.sam\n";
		    print OUT2 "echo \"got here \"\n";
		    close(OUT2);
		    while (qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
		}
		if (-e "$final_NU_dir/$id.FINAL.norm_nu.sam"){
		    open(OUT2, ">$norm_shfile");
		    print OUT2 "samtools view -bt $fai_file $final_NU_dir/$id.FINAL.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.bam \n";
		    print OUT2 "rm $final_NU_dir/$id.FINAL.norm_nu.sam\n";
		    print OUT2 "echo \"got here \"\n";
		    close(OUT2);
		    while (qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_norm.out -e $logname_norm.err < $norm_shfile`;
		}
		else{
		    print STDOUT "WARNING: normalized sam file \"$final_M_dir/$id.FINAL.norm.sam\", \"$final_U_dir/$id.FINAL.norm_u.sam\", or \"$final_NU_dir/$id.FINAL.norm_nu.sam\" does not exist. Please check the input samfile name/path\n\n";
		}
	    }
	}
	else{
	    print STDOUT "WARNING: file \"$LOC/$line/$sam_name\" doesn't exist. please check the input samfile name/path\n\n.";
	}
	
    }
}
if ($gzip_cov eq 'true'){
    if (-d $cov_dir){
	@a = glob("$cov_dir/*/*cov");
	if (@a > 0){
	    @g = glob("$cov_dir/*/*gz");
	    if (@g eq 0){
		`gzip $cov_dir/*/*cov`;
	    }
	}
    }
}
	
print "got here\n";
