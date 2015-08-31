#!/usr/bin/env perl
use warnings;
#use strict;
my $USAGE =  "\nUsage: perl runall_compress.pl <sample dirs> <loc> <sam file name> <fai file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<fai file> fai file (full path)

option:
 -bam : set this if the input aligned files are in bam format

 -samtools <s> : provide location of samtools <s>

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
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. 6144, 6G)
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
my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $gzip_cov = 'true';
my $sam2bam = 'true';
my $njobs = 200;
my ($status, $new_mem) ;
my $samtools = "";
my $bam = "false";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=4; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-samtools'){
        $option_found = 'true';
        $samtools = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-bam'){
	$bam = "true";
	$option_found = "true";
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
        $request_memory_option = "-M";
        $mem = "6144";
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
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
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

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $norm_dir = $study_dir . "NORMALIZED_DATA/EXON_INTRON_JUNCTION";
my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers";
my $ig_dir = $norm_dir . "/FINAL_SAM/intergenicmappers";
my $und_dir = $norm_dir . "/FINAL_SAM/exon_inconsistent";
my $merged_dir = $norm_dir . "/FINAL_SAM/merged";
my $cov_dir = "$norm_dir/COV/";

my $gnorm_dir = $study_dir . "NORMALIZED_DATA/GENE";
my $gfinalsam_dir = "$gnorm_dir/FINAL_SAM";
my $gmerged_dir = "$gfinalsam_dir/merged";
my $gcov_dir = "$gnorm_dir/COV/";

my $sam_name = $ARGV[2];
my $bam_name = $sam_name;
$bam_name =~ s/.sam$/.bam/i;
my $fai_file = $ARGV[3];
if ($sam2bam eq 'true'){
    unless (-e $samtools){
	die "cannot find $samtools\n\n";
    }
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    while (my $line = <INFILE>){
	chomp($line);
	my $dir = $line;
	my $id = $line;
	#originalsam
	my $shfile = "$shdir/$id.sam2bam.sh";
	my $jobname = "$study.compress";
	my $logname = "$logdir/sam2bam.$id";
	my $samname = "$LOC/$dir/$sam_name";
	my $bamname = "$LOC/$dir/$bam_name";
	#mergedsam
	my $shfile_m = "$shdir/$id.sam2bam.norm.merged.sh";
	my $logname_m = "$logdir/sam2bam.norm.merged.$id";
	my $samname_m = "$merged_dir/$id.merged.sam";
	my $bamname_m = $samname_m;
	$bamname_m =~ s/.sam$/.bam/;
	#exonmapper
	my $shfile_ex = "$shdir/$id.sam2bam.norm.exon.sh";
	my $samname_ex = "$exon_dir/$id.exonmappers.norm.sam";
	my $logname_ex = "$logdir/sam2bam.norm.exon.$id";
	if (-d "$exon_dir/sense"){
	    $samname_ex = "$exon_dir/sense/$id.exonmappers.norm.sam";
	    $logname_ex = "$logdir/sam2bam.norm.exon.s.$id";
	}
	my $bamname_ex = $samname_ex;
	$bamname_ex =~ s/.sam$/.bam/;
	my ($shfile_ex_a, $logname_ex_a, $bamname_ex_a);
	my $samname_ex_a = "";
	if (-d "$exon_dir/antisense"){
	    $shfile_ex_a = "$shdir/$id.sam2bam.norm.exon.a.sh";
	    $logname_ex_a = "$logdir/sam2bam.norm.exon.a.$id";
	    $samname_ex_a = "$exon_dir/antisense/$id.exonmappers.norm.sam";
	    $bamname_ex_a = $samname_ex_a;
	    $bamname_ex_a =~ s/.sam$/.bam/;
	}
	#intronmapper
	my $shfile_int = "$shdir/$id.sam2bam.norm.intron.sh";
	my $logname_int = "$logdir/sam2bam.norm.intron.$id";
	my $samname_int = "$intron_dir/$id.intronmappers.norm.sam";
	if (-d "$intron_dir/sense"){
            $samname_int = "$intron_dir/sense/$id.intronmappers.norm.sam";
            $logname_int = "$logdir/sam2bam.norm.intron.s.$id";
        }
	my $bamname_int = $samname_int;
        $bamname_int =~ s/.sam$/.bam/;
        my ($shfile_int_a, $logname_int_a, $bamname_int_a);
	my $samname_int_a = "";
	if (-d "$intron_dir/antisense"){
            $shfile_int_a = "$shdir/$id.sam2bam.norm.intron.a.sh";
            $logname_int_a = "$logdir/sam2bam.norm.intron.a.$id";
            $samname_int_a = "$intron_dir/antisense/$id.intronmappers.norm.sam";
            $bamname_int_a = $samname_int_a;
            $bamname_int_a =~ s/.sam$/.bam/;
        }
	#intergenic
	my $shfile_ig = "$shdir/$id.sam2bam.norm.intergenic.sh";
	my $logname_ig = "$logdir/sam2bam.norm.intergenic.$id";
	my $samname_ig = "$ig_dir/$id.intergenicmappers.norm.sam";
        my $bamname_ig = $samname_ig;
	$bamname_ig =~ s/.sam$/.bam/;
	#exon_inconsistent
	my $shfile_und = "$shdir/$id.sam2bam.norm.exon_inconsistent.sh";
	my $logname_und = "$logdir/sam2bam.norm.exon_inconsistent.$id";
	my $samname_und = "$und_dir/$id.exon_inconsistent_reads.norm.sam";
        my $bamname_und = $samname_und;
	$bamname_und =~ s/.sam$/.bam/;
	#gene
	my $shfile_g = "$shdir/$id.sam2bam.norm.gene.sh";
        my $logname_g = "$logdir/sam2bam.norm.gene.$id";
        my $samname_g = "$gfinalsam_dir/$id.gene.norm.sam";
        if (-d "$gfinalsam_dir/sense"){
            $samname_g = "$gfinalsam_dir/sense/$id.gene.norm.sam";
            $logname_g = "$logdir/sam2bam.norm.gene.s.$id";
        }
        my $bamname_g = $samname_g;
	$bamname_g =~ s/.sam$/.bam/;
        my ($shfile_g_a, $logname_g_a,  $bamname_g_a);
	my $samname_g_a = "";
        if (-d "$gfinalsam_dir/antisense"){
            $shfile_g_a = "$shdir/$id.sam2bam.norm.gene.a.sh";
            $logname_g_a = "$logdir/sam2bam.norm.gene.a.$id";
            $samname_g_a = "$gfinalsam_dir/antisense/$id.gene.norm.sam";
            $bamname_g_a = $samname_g_a;
            $bamname_g_a =~ s/.sam$/.bam/;
        }
	#gmerged
        my $shfile_g_m = "$shdir/$id.sam2bam.norm.merged.gene.sh";
        my $logname_g_m = "$logdir/sam2bam.norm.merged.gene.$id";
        my $samname_g_m = "$gmerged_dir/$id.merged.sam";
	my $bamname_g_m = $samname_g_m;
	$bamname_g_m =~ s/.sam$/.bam/;
	#original
	if ($bam eq "false"){
	    if (-e "$samname"){
		my $sam = $samname;
		my $bam = $bamname;
		my $sh = $shfile;
		my $log = $logname;
		open(OUT, ">$sh");
		print OUT "$samtools view -bt $fai_file $sam > $bam\n";
		print OUT "lc=`cat $bam | wc -l`\n";
		print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
		print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
		print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
		print OUT "echo \"got here \"\n";
		close(OUT);
		while (qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
	    }
	    else{
		print STDOUT "WARNING: file \"$LOC/$line/$sam_name\" doesn't exist. please check the input samfile name/path\n\n";
	    }
	}
	else{ #input bam
	    if (-e $samname){
		my $x = `rm $samname`;
	    }
	}
	#merged
	if (-e "$samname_m"){
            my $sam = $samname_m;
            my $bam = $bamname_m;
            my $sh = $shfile_m;
            my $log = $logname_m;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
	#exon
        if (-e "$samname_ex"){
            my $sam = $samname_ex;
            my $bam = $bamname_ex;
            my $sh = $shfile_ex;
            my $log = $logname_ex;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        else{
            print STDOUT "WARNING: file \"$samname_ex\" doesn't exist. please check the input samfile name/path\n\n";
        }
        #exon_a
        if (-e "$samname_ex_a"){
            my $sam = $samname_ex_a;
            my $bam = $bamname_ex_a;
            my $sh = $shfile_ex_a;
            my $log = $logname_ex_a;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        #intron
        if (-e "$samname_int"){
            my $sam = $samname_int;
            my $bam = $bamname_int;
            my $sh = $shfile_int;
            my $log = $logname_int;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        else{
            print STDOUT "WARNING: file \"$samname_int\" doesn't exist. please check the input samfile name/path\n\n";
        }
        #intron_a
        if (-e "$samname_int_a"){
            my $sam = $samname_int_a;
            my $bam = $bamname_int_a;
            my $sh = $shfile_int_a;
            my $log = $logname_int_a;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        #ig
        if (-e "$samname_ig"){
            my $sam = $samname_ig;
            my $bam = $bamname_ig;
            my $sh = $shfile_ig;
            my $log = $logname_ig;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        #und
        if (-e "$samname_und"){
            my $sam = $samname_und;
            my $bam = $bamname_und;
            my $sh = $shfile_und;
            my $log = $logname_und;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        #gene
        if (-e "$samname_g"){
            my $sam = $samname_g;
            my $bam = $bamname_g;
            my $sh = $shfile_g;
            my $log = $logname_g;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
        else{
            print STDOUT "WARNING: file \"$samname_g\" doesn't exist. please check the input samfile name/path\n\n";
        }
	#gene-a
        if (-e "$samname_g_a"){
            my $sam = $samname_g_a;
            my $bam = $bamname_g_a;
            my $sh = $shfile_g_a;
            my $log = $logname_g_a;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
	#gene_m
        if (-e "$samname_g_m"){
            my $sam = $samname_g_m;
            my $bam = $bamname_g_m;
            my $sh = $shfile_g_m;
            my $log = $logname_g_m;
            open(OUT, ">$sh");
            print OUT "$samtools view -bt $fai_file $sam > $bam\n";
            print OUT "lc=`cat $bam | wc -l`\n";
            print OUT "if [ \"\$lc\" -ne 0 ]; then rm $sam\n";
            print OUT "else $samtools view -bt $fai_file $sam > $bam\n";
            print OUT "echo sam2bam ran twice for '$sam'. please make sure '$bam' file is not empty and delete the sam file >> $logdir/$study.sam2bam.log\nfi\n";
            print OUT "echo \"got here \"\n";
            close(OUT);
            while (qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $log.out -e $log.err < $sh`;
        }
    }
}
if ($gzip_cov eq 'true'){
    if (-d $cov_dir){
	my @a = glob("$cov_dir/*cov");
	if (@a > 0){
	    my @g = glob("$cov_dir/*gz");
	    if (@g eq 0){
		`gzip $cov_dir/*cov`;
	    }
	}
    }
    if (-d $gcov_dir){
        my @a = glob("$gcov_dir/*cov");
        if (@a > 0){
            my @g = glob("$gcov_dir/*gz");
            if (@g eq 0){
                `gzip $gcov_dir/*cov`;
            }
        }
    }
}
	
print "got here\n";
