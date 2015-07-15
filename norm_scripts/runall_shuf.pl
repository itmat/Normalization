#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_shuf.pl <sample_dirs> <loc> [options]

where
<sample_dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs

will output the same number of rows from each file in <loc>/<dirs>/Unique
of the same type. (ditto for NU)

The output file names will be modified from the input file names.

** If the maximum line count in `STUDY/READS/sample_dir/EIJ/Unique/linecounts.txt` is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

option:  

 -stranded : set this if your data are stand-specific

 -u  :  set this if you want to return only unique mappers, otherwise by default it will return both unique and non-unique mappers

 -nu  :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-unique mappers

 -depthE <n> : This is the number of exonmappers file used for normalization.
               By default, <n> = 20.

 -depthI <n> : This is the number of intronmappers file used for normalization.
               By default, <n> = 10. 

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command  (e.g. -M, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. 6144, 6G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -h : print usage

";
if (@ARGV <2){
    die $USAGE;
}

$U = 'true';
$NU = 'true';
$numargs_u_nu = 0;
$i_exon = 20;
$i_intron = 10;
$njobs = 200;
$replace_mem = "false";
$submit = "";
$request_memory_option = "";
$mem = "";
$jobname_option = "";
$numargs = 0;
$stranded = "false";
for ($i=2; $i<@ARGV; $i++){
    $option_found = "false";
    $option_u_nu = "false";
    if ($ARGV[$i] eq '-max_jobs'){
	$option_found = "true";
	$njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-u'){
	$NU = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_u_nu++;
    }
    if ($ARGV[$i] eq '-nu'){
	$U = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_u_nu++;
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthE'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthE <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthI'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthI <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$status = "bjobs";
	$request_memory_option = "-M";
	$mem = "6144";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
	$jobname_option = "-N";
	$status = "qstat";
	$request_memory_option = "-l h_vmem=";
	$mem = "6G";
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
        if ($submit =~ /^-/ | $submit eq "" | $jobname_option eq "" | $status eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
	    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>\".\n";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_shuf.pl//;

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
%LINECOUNTS;

if ($U eq 'true'){
    #EXON
    $exonuniques = "false";
    $warnUE = "";
    for($i=1; $i<=$i_exon; $i++) {
	open(INFILE, $ARGV[0]);  # file of dirs
	$minEU[$i] = 1000000000000;
	$minEU_S[$i] = 1000000000000;
	$minEU_A[$i] = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if ($stranded eq "false"){
		if(-e "$LOC/$dirname/EIJ/Unique/$id.filtered_u_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/EIJ/Unique/$id.filtered_u_exonmappers.$i.sam`;
		} 
		else {
		    die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"EU.$id.$i"} = $N;
		if($N < $minEU[$i]) {
		    $minEU[$i] = $N;
		}
	    }
	    if ($stranded eq "true"){
		#sense
		if (-e "$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_exonmappers.$i.sam"){
		    $N = `tail -1 $LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_exonmappers.$i.sam`;
		}
		else{
		    die "ERROR: The file '$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if ($N !~ /line count/){
		    die "ERROR: The file '$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
                $LINECOUNTS{"EU_S.$id.$i"} = $N;
                if($N < $minEU_S[$i]) {
                    $minEU_S[$i] = $N;
                }
		#antisense
		if (-e "$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_exonmappers.$i.sam"){
                    $N = `tail -1 $LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_exonmappers.$i.sam`;
		}
		else{
                    die"ERROR: The file '$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if ($N !~ /line count/){
                    die"ERROR: The file '$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
                $LINECOUNTS{"EU_A.$id.$i"} = $N;
                if($N < $minEU_A[$i]) {
                    $minEU_A[$i] = $N;
                }
	    }	
	}    
	close(INFILE);
    }

    if ($i_intron ne '0'){
	#INTRON
	for($i=1; $i<=$i_intron; $i++) {
	    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
	    $minIU[$i] = 1000000000000;
	    $minIU_S[$i] = 1000000000000;
	    $minIU_A[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if ($stranded eq "false"){
		    if(-e "$LOC/$dirname/EIJ/Unique/$id.filtered_u_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/EIJ/Unique/$id.filtered_u_intronmappers.$i.sam`;
		    } 
		    else {
			die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"IU.$id.$i"} = $N;
		    if($N < $minIU[$i]) {
			$minIU[$i] = $N;
		    }
		}
		if ($stranded eq "true"){
		    #sense
                    if (-e "$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_intronmappers.$i.sam"){
                        $N = `tail -1 $LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_intronmappers.$i.sam`;
                    }
                    else{
                        die"ERROR: The file '$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_intronmappers.$i.sam' does not seem to exist...\n";
                    }
                    if ($N !~ /line count/){
                        die"ERROR: The file '$LOC/$dirname/EIJ/Unique/sense/$id.filtered_u_intronmappers.$i.sam' does not seem to have the proper last line...\n";
                    }
		    $N =~ s/[^\d]//g;
                    $LINECOUNTS{"IU_S.$id.$i"} = $N;
                    if($N < $minIU_S[$i]) {
                        $minIU_S[$i] = $N;
                    }
		    #antisense
		    if (-e "$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_intronmappers.$i.sam"){
			$N = `tail -1 $LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_intronmappers.$i.sam`;
		    }
		    else{
			die"ERROR: The file '$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if ($N !~ /line count/){
			die"ERROR: The file '$LOC/$dirname/EIJ/Unique/antisense/$id.filtered_u_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"IU_A.$id.$i"} = $N;
		    if($N < $minIU_A[$i]) {
			$minIU_A[$i] = $N;
		    }
		}
	    }
	    close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	}
	#INTERGENIC
	open(INFILE, $ARGV[0]);  # file of dirs
	$minIGU = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if(-e "$LOC/$dirname/EIJ/Unique/$id.filtered_u_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/EIJ/Unique/$id.filtered_u_intergenicmappers.sam`;
	    } 
	    else {
		die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"IGU.$id"} = $N;
	    if($N < $minIGU) {
		$minIGU = $N;
	    }
	}
	close(INFILE);
	#EXON_INCONSISTENT
	open(INFILE, $ARGV[0]);
	$minUND_U = 1000000000000;
	while($dirname = <INFILE>) {
            chomp($dirname);
            $id = $dirname;
            if(-e "$LOC/$dirname/EIJ/Unique/$id.filtered_u_exon_inconsistent_reads.sam"){
		$N = `tail -1 $LOC/$dirname/EIJ/Unique/$id.filtered_u_exon_inconsistent_reads.sam`;
	    }
	    else {
                die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_exon_inconsistent_reads.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
                die "ERROR: The file '$LOC/$dirname/EIJ/Unique/$id.filtered_u_exon_inconsistent_reads.sam' does not seem to have the proper last line...\n";
            }
            $N =~ s/[^\d]//g;
            $LINECOUNTS{"UND_U.$id"} = $N;
            if($N < $minUND_U) {
                $minUND_U = $N;
            }
	}
	close(INFILE);
    }
}
if ($NU eq 'true'){
    #EXON
    for($i=1; $i<=$i_exon; $i++) {
	open(INFILE, $ARGV[0]);  # file of dirs
	$minENU[$i] = 1000000000000;
	$minENU_S[$i] = 1000000000000;
	$minENU_A[$i] = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if ($stranded eq "false"){
		if(-e "$LOC/$dirname/EIJ/NU/$id.filtered_nu_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/EIJ/NU/$id.filtered_nu_exonmappers.$i.sam`;
		} 
		else {
		    die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		$LINECOUNTS{"ENU.$id.$i"} = $N;
		if($N < $minENU[$i]) {
		    $minENU[$i] = $N;
		}
	    }
	    if ($stranded eq "true"){
		if ($stranded eq "true"){
		    #sense
		    if (-e "$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_exonmappers.$i.sam"){
			$N = `tail -1 $LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_exonmappers.$i.sam`;
		    }
		    else{
			die "ERROR: The file '$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
		    }
		    if ($N !~ /line count/){
			die "ERROR: The file '$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"ENU_S.$id.$i"} = $N;
		    if($N < $minENU_S[$i]) {
			$minENU_S[$i] = $N;
		    }
		    #antisense
		    if (-e "$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_exonmappers.$i.sam"){
			$N = `tail -1 $LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_exonmappers.$i.sam`;
		    }
		    else{
			die"ERROR: The file '$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
		    }
		    if ($N !~ /line count/){
			die"ERROR: The file '$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"ENU_A.$id.$i"} = $N;
		    if($N < $minENU_A[$i]) {
			$minENU_A[$i] = $N;
		    }
		}
	    }
	}
	close(INFILE);
#    print "minEU[$i] = $minEU[$i]\n";
#    print "minENU[$i] = $minENU[$i]\n";
    }
    if ($i_intron ne '0'){
        #INTRON
	for($i=1; $i<=$i_intron; $i++) {
	    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
	    $minINU[$i] = 1000000000000;
	    $minINU_S[$i] = 1000000000000;
	    $minINU_A[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		if ($stranded eq "false"){
		    if(-e "$LOC/$dirname/EIJ/NU/$id.filtered_nu_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/EIJ/NU/$id.filtered_nu_intronmappers.$i.sam`;
		    } 
		    else {
			die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    $LINECOUNTS{"INU.$id.$i"} = $N;
		    if($N < $minINU[$i]) {
			$minINU[$i] = $N;
		    }
		}
		if ($stranded eq "true"){
		    #sense
                    if (-e "$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_intronmappers.$i.sam"){
                        $N = `tail -1 $LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_intronmappers.$i.sam`;
                    }
                    else{
                        die"ERROR: The file '$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_intronmappers.$i.sam' does not seem to exist...\n";
                    }
                    if ($N !~ /line count/){
                        die"ERROR: The file '$LOC/$dirname/EIJ/NU/sense/$id.filtered_nu_intronmappers.$i.sam' does not seem to have the proper last line...\n";
                    }
                    $N =~ s/[^\d]//g;
                    $LINECOUNTS{"INU_S.$id.$i"} = $N;
                    if($N < $minINU_S[$i]) {
                        $minINU_S[$i] = $N;
                    }
                    #antisense
                    if (-e "$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_intronmappers.$i.sam"){
                        $N = `tail -1 $LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_intronmappers.$i.sam`;
                    }
                    else{
                        die"ERROR: The file '$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_intronmappers.$i.sam' does not seem to exist...\n";
                    }
                    if ($N !~ /line count/){
                        die"ERROR: The file '$LOC/$dirname/EIJ/NU/antisense/$id.filtered_nu_intronmappers.$i.sam' does not seem to have the proper last line...\n";
                    }
		    $N =~ s/[^\d]//g;
                    $LINECOUNTS{"INU_A.$id.$i"} = $N;
                    if($N < $minINU_A[$i]) {
                        $minINU_A[$i] = $N;
                    }
		}
	    }
	    close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	}
	#INTERGENIC
	open(INFILE, $ARGV[0]);  # file of dirs
	$minIGNU = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    if(-e "$LOC/$dirname/EIJ/NU/$id.filtered_nu_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/EIJ/NU/$id.filtered_nu_intergenicmappers.sam`;
	    } else {
		die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    $LINECOUNTS{"IGNU.$id"} = $N;
	    if($N < $minIGNU) {
		$minIGNU = $N;
	    }
	}
	close(INFILE);
#print "minIGU = $minIGU\n";
#print "minIGNU = $minIGNU\n";
        #EXON_INCONSISTENT
        open(INFILE, $ARGV[0]);
        $minUND_NU = 1000000000000;
	while($dirname = <INFILE>) {
            chomp($dirname);
            $id = $dirname;
            if(-e "$LOC/$dirname/EIJ/NU/$id.filtered_nu_exon_inconsistent_reads.sam"){
		$N = `tail -1 $LOC/$dirname/EIJ/NU/$id.filtered_nu_exon_inconsistent_reads.sam`;
            }
            else {
                die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_exon_inconsistent_reads.sam' does not seem to exist...\n";
            }
            if($N !~ /line count/) {
                die "ERROR: The file '$LOC/$dirname/EIJ/NU/$id.filtered_nu_exon_inconsistent_reads.sam' does not seem to have the proper last line...\n";
            }
            $N =~ s/[^\d]//g;
            $LINECOUNTS{"UND_NU.$id"} = $N;
            if($N < $minUND_NU) {
                $minUND_NU = $N;
            }
	}
	close(INFILE);
    }
}


##run shuf
$jobname = "$study.shuf";
#exonmappers
for($i=1; $i<=$i_exon; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$dirU = $dirname . "/EIJ/Unique";
	$dirNU = $dirname . "/EIJ/NU";
	
	#unique
	$filenameU = "$id.filtered_u_exonmappers.$i.sam";
	$outfileU = $filenameU;
	$outfileU_S = $filenameU;
	$outfileU_A = $filenameU;
	$checkU = $filenameU;
	$checkU =~ s/.sam$//g;
	$checkU = $checkU . "_shuf_*.sam";
	#nu
	$filenameNU = "$id.filtered_nu_exonmappers.$i.sam";
	$outfileNU = $filenameNU;
	$outfileNU_S = $filenameNU;
	$outfileNU_A = $filenameNU;
	$checkNU = $filenameNU;
	$checkNU =~ s/.sam$//g;
	$checkNU = $checkNU . "_shuf_*.sam";

	if ($stranded eq "true"){
	    $for_lc_s = "EU_S.$id.$i";
	    $for_lc_a = "EU_A.$id.$i";
	    $total_lc_s = $LINECOUNTS{$for_lc_s};
	    $total_lc_a = $LINECOUNTS{$for_lc_a};
	    $numU_S = $minEU_S[$i];
	    $numU_A = $minEU_A[$i];
	    $numNU_S = $minENU_S[$i];
	    $numNU_A = $minENU_A[$i];
	    @g = glob("$LOC/$dirU/sense/$checkU");
	    if (@g ne '0'){
                `rm $LOC/$dirU/sense/$checkU`;
            }
	    @g = glob("$LOC/$dirU/antisense/$checkU");
	    if (@g ne '0'){
                `rm $LOC/$dirU/antisense/$checkU`;
            }
            @g = glob("$LOC/$dirNU/sense/$checkNU");
            if (@g ne '0'){
                `rm $LOC/$dirNU/sense/$checkNU`;
            }
            @g = glob("$LOC/$dirNU/antisense/$checkNU");
            if (@g ne '0'){
                `rm $LOC/$dirNU/antisense/$checkNU`;
	    }
	    $outfileU_S =~ s/.sam$/_shuf_$numU_S.sam/;
	    $outfileU_A =~ s/.sam$/_shuf_$numU_A.sam/;
	    $outfileNU_S =~ s/.sam$/_shuf_$numNU_S.sam/;
	    $outfileNU_A =~ s/.sam$/_shuf_$numNU_A.sam/;
            $shfileU_S[$i] = "$shdir/a" . $id . "exonmappers.u_runshuf.$i.sense.sh";
            $shfileU_A[$i] = "$shdir/a" . $id . "exonmappers.u_runshuf.$i.antisense.sh";
            $shfileNU_S[$i] = "$shdir/a" . $id . "exonmappers.nu_runshuf.$i.sense.sh";
            $shfileNU_A[$i] = "$shdir/a" . $id . "exonmappers.nu_runshuf.$i.antisense.sh";
            $lognameU_S[$i] = "$logdir/shuf.$id.exonmappers.u.$i.sense";
            $lognameU_A[$i] = "$logdir/shuf.$id.exonmappers.u.$i.antisense";
            $lognameNU_S[$i] = "$logdir/shuf.$id.exonmappers.nu.$i.sense";
            $lognameNU_A[$i] = "$logdir/shuf.$id.exonmappers.nu.$i.antisense";

	    if($U eq 'true') {
                if (($total_lc_s ne '0') && ($numU_S ne '0')){
                    open(OUTFILEU, ">$shfileU_S[$i]");
                    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/sense/$filenameU $total_lc_s $numU_S > $LOC/$dirU/sense/$outfileU_S\n";
                    print OUTFILEU "echo \"got here\"\n";
                    close(OUTFILEU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU_S[$i].out -e $lognameU_S[$i].err < $shfileU_S[$i]`;
                }
		if (($total_lc_a ne '0') && ($numU_A ne '0')){
		    open(OUTFILEU, ">$shfileU_A[$i]");
                    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/antisense/$filenameU $total_lc_a $numU_A > $LOC/$dirU/antisense/$outfileU_A\n";
                    print OUTFILEU "echo \"got here\"\n";
                    close(OUTFILEU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU_A[$i].out -e $lognameU_A[$i].err < $shfileU_A[$i]`;
                }
            }
            if($NU eq 'true') {
                $for_lc_s =~ s/EU/ENU/g;
                $total_lc_s = $LINECOUNTS{$for_lc_s};
                $for_lc_a =~ s/EU/ENU/g;
                $total_lc_a = $LINECOUNTS{$for_lc_a};
                if (($total_lc_s ne '0') && ($numNU_S ne '0')){
                    open(OUTFILENU, ">$shfileNU_S[$i]");
                    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/sense/$filenameNU $total_lc_s $numNU_S > $LOC/$dirNU/sense/$outfileNU_S\n";
                    print OUTFILENU "echo \"got here\"\n";;
                    close(OUTFILENU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU_S[$i].out -e $lognameNU_S[$i].err < $shfileNU_S[$i]`;
                }
		if (($total_lc_a ne '0') && ($numNU_A ne '0')){
                    open(OUTFILENU, ">$shfileNU_A[$i]");
                    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/antisense/$filenameNU $total_lc_a $numNU_A > $LOC/$dirNU/antisense/$outfileNU_A\n";
                    print OUTFILENU "echo \"got here\"\n";;
                    close(OUTFILENU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU_A[$i].out -e $lognameNU_A[$i].err < $shfileNU_A[$i]`;
                }
            }
	}

	if ($stranded eq "false"){
	    $for_lc = "EU.$id.$i";
	    $total_lc = $LINECOUNTS{$for_lc};
	    $numU = $minEU[$i];
	    $numNU = $minENU[$i];
	    $outfileU =~ s/.sam$/_shuf_$numU.sam/;
	    $outfileNU =~ s/.sam$/_shuf_$numNU.sam/;
	    @g = glob("$LOC/$dirU/$checkU");
	    if (@g ne '0'){
		`rm $LOC/$dirU/$checkU`;
	    }
	    @g = glob("$LOC/$dirNU/$checkNU");
	    if (@g ne '0'){
		`rm $LOC/$dirNU/$checkNU`;
	    }
	    $shfileU[$i] = "$shdir/a" . $id . "exonmappers.u_runshuf.$i.sh";
	    $shfileNU[$i] = "$shdir/a" . $id . "exonmappers.nu_runshuf.$i.sh";
	    $lognameU[$i] = "$logdir/shuf.$id.exonmappers.u.$i";
	    $lognameNU[$i] = "$logdir/shuf.$id.exonmappers.nu.$i";
	    if($U eq 'true') {
		if (($total_lc ne '0') && ($numU ne '0')){
		    open(OUTFILEU, ">$shfileU[$i]");
		    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
		    print OUTFILEU "echo \"got here\"\n";
		    close(OUTFILEU);
		    while(qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU[$i].out -e $lognameU[$i].err < $shfileU[$i]`;
		}
	    }
	    if($NU eq 'true') {
		$for_lc =~ s/EU/ENU/g;
		$total_lc = $LINECOUNTS{$for_lc};
		if (($total_lc ne '0') && ($numNU ne '0')){
		    open(OUTFILENU, ">$shfileNU[$i]");
		    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
		    print OUTFILENU "echo \"got here\"\n";;
		    close(OUTFILENU);
		    while(qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU[$i].out -e $lognameNU[$i].err < $shfileNU[$i]`;
		}
	    }
	}
    }
}
close(INFILE);

#intronmappers
for($i=1; $i<=$i_intron; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$dirU = $dirname . "/EIJ/Unique";
	$dirNU = $dirname . "/EIJ/NU";
	$filenameU = "$id.filtered_u_intronmappers.$i.sam";
	$filenameNU = "$id.filtered_nu_intronmappers.$i.sam";
	#unique
        $checkU = $filenameU;
        $checkU =~ s/.sam$//g;
        $checkU = $checkU . "_shuf_*.sam";
	#nu
        $checkNU = $filenameNU;
        $checkNU =~ s/.sam$//g;
        $checkNU = $checkNU . "_shuf_*.sam";
	if ($stranded eq "true"){
	    $for_lc_s = "IU_S.$id.$i";
            $total_lc_s = $LINECOUNTS{$for_lc_s};
            $numU_S = $minIU_S[$i];
            $numNU_S = $minINU_S[$i];
	    $for_lc_a = "IU_A.$id.$i";
            $total_lc_a = $LINECOUNTS{$for_lc_a};
            $numU_A = $minIU_A[$i];
            $numNU_A = $minINU_A[$i];
	    @g = glob("$LOC/$dirU/sense/$checkU");
	    if (@g ne '0'){
                `rm $LOC/$dirU/sense/$checkU`;
            }
            $outfileU_S = $filenameU;
	    $outfileU_S =~ s/.sam$/_shuf_$numU_S.sam/;
	    @g = glob("$LOC/$dirU/antisense/$checkU");
	    if (@g ne '0'){
                `rm $LOC/$dirU/antisense/$checkU`;
            }
            $outfileU_A = $filenameU;
	    $outfileU_A =~ s/.sam$/_shuf_$numU_A.sam/;

	    @g = glob("$LOC/$dirNU/sense/$checkNU");
            if (@g ne '0'){
                `rm $LOC/$dirNU/sense/$checkNU`;
            }
            $outfileNU_S = $filenameNU;
            $outfileNU_S =~ s/.sam$/_shuf_$numNU_S.sam/;

	    @g = glob("$LOC/$dirNU/antisense/$checkNU");
            if (@g ne '0'){
                `rm $LOC/$dirNU/antisense/$checkNU`;
            }
            $outfileNU_A = $filenameNU;
            $outfileNU_A =~ s/.sam$/_shuf_$numNU_A.sam/;

	    $shfileU_S[$i] = "$shdir/a" . $id . "intronmappers.u_runshuf.$i.sense.sh";
            $shfileNU_S[$i] = "$shdir/a" . $id . "intronmappers.nu_runshuf.$i.sense.sh";
            $lognameU_S[$i] = "$logdir/shuf.$id.intronmappers.u.$i.sense";
            $lognameNU_S[$i] = "$logdir/shuf.$id.intronmappers.nu.$i.sense";

	    $shfileU_A[$i] = "$shdir/a" . $id . "intronmappers.u_runshuf.$i.antisense.sh";
            $shfileNU_A[$i] = "$shdir/a" . $id . "intronmappers.nu_runshuf.$i.antisense.sh";
            $lognameU_A[$i] = "$logdir/shuf.$id.intronmappers.u.$i.antisense";
            $lognameNU_A[$i] = "$logdir/shuf.$id.intronmappers.nu.$i.antisense";
	    
	    if($U eq 'true') {
                if (($total_lc_s ne '0') && ($numU_S ne '0')){
                    open(OUTFILEU, ">$shfileU_S[$i]");
                    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/sense/$filenameU $total_lc_s $numU_S > $LOC/$dirU/sense/$outfileU_S\n";
                    print OUTFILEU "echo \"got here\"\n";;
                    close(OUTFILEU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU_S[$i].out -e $lognameU_S[$i].err < $shfileU_S[$i]`;
                }
                if (($total_lc_a ne '0') && ($numU_A ne '0')){
                    open(OUTFILEU, ">$shfileU_A[$i]");
                    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/antisense/$filenameU $total_lc_a $numU_A > $LOC/$dirU/antisense/$outfileU_A\n";
                    print OUTFILEU "echo \"got here\"\n";;
                    close(OUTFILEU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU_A[$i].out -e $lognameU_A[$i].err < $shfileU_A[$i]`;
                }
            }
	    if($NU eq 'true') {
                $for_lc_s =~ s/IU/INU/g;
		$total_lc_s = $LINECOUNTS{$for_lc_s};
                $for_lc_a =~ s/IU/INU/g;
		$total_lc_a = $LINECOUNTS{$for_lc_a};
		if (($total_lc_s ne '0') && ($numNU_S ne '0')){
                    open(OUTFILENU, ">$shfileNU_S[$i]");
                    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/sense/$filenameNU $total_lc_s $numNU_S > $LOC/$dirNU/sense/$outfileNU_S\n";
                    print OUTFILENU "echo \"got here\"\n";;
                    close(OUTFILENU);
                    while(qx{$status | wc -l} > $njobs){
			sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU_S[$i].out -e $lognameNU_S[$i].err < $shfileNU_S[$i]`;
		}
		if (($total_lc_a ne '0') && ($numNU_A ne '0')){
                    open(OUTFILENU, ">$shfileNU_A[$i]");
                    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/antisense/$filenameNU $total_lc_a $numNU_A > $LOC/$dirNU/antisense/$outfileNU_A\n";
                    print OUTFILENU "echo \"got here\"\n";;
                    close(OUTFILENU);
                    while(qx{$status | wc -l} > $njobs){
			sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU_A[$i].out -e $lognameNU_A[$i].err < $shfileNU_A[$i]`;
		}
	    }

	}
	if ($stranded eq "false"){
	    $for_lc = "IU.$id.$i";
	    $total_lc = $LINECOUNTS{$for_lc};
	    $numU = $minIU[$i];
	    $numNU = $minINU[$i];
	    @g = glob("$LOC/$dirU/$checkU");
	    if (@g ne '0'){
		`rm $LOC/$dirU/$checkU`;
	    }
	    $outfileU = $filenameU;
	    $outfileU =~ s/.sam$/_shuf_$numU.sam/;
	    @g = glob("$LOC/$dirNU/$checkNU");
	    if (@g ne '0'){
		`rm $LOC/$dirNU/$checkNU`;
	    }
	    $outfileNU = $filenameNU;
	    $outfileNU =~ s/.sam$/_shuf_$numNU.sam/;

	    $shfileU[$i] = "$shdir/a" . $id . "intronmappers.u_runshuf.$i.sh";
	    $shfileNU[$i] = "$shdir/a" . $id . "intronmappers.nu_runshuf.$i.sh";
	    $lognameU[$i] = "$logdir/shuf.$id.intronmappers.u.$i";
	    $lognameNU[$i] = "$logdir/shuf.$id.intronmappers.nu.$i";
	    if($U eq 'true') {
		if (($total_lc ne '0') && ($numU ne '0')){
		    open(OUTFILEU, ">$shfileU[$i]");
		    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
		    print OUTFILEU "echo \"got here\"\n";;
		    close(OUTFILEU);
		    while(qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU[$i].out -e $lognameU[$i].err < $shfileU[$i]`;
		}
	    }
	    if($NU eq 'true') {
		$for_lc =~ s/IU/INU/g;
		$total_lc = $LINECOUNTS{$for_lc};
		if (($total_lc ne '0') && ($numNU ne '0')){
		    open(OUTFILENU, ">$shfileNU[$i]");
		    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
		    print OUTFILENU "echo \"got here\"\n";;
		    close(OUTFILENU);
		    while(qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU[$i].out -e $lognameNU[$i].err < $shfileNU[$i]`;
		}
	    }
	}
    }
    close(INFILE);
}

#intergenicmappers
open(INFILE, $ARGV[0]);
while($dirname = <INFILE>) {
    chomp($dirname);
    $id = $dirname;
    $for_lc = "IGU.$id";
    $total_lc = $LINECOUNTS{$for_lc};
    $numU = $minIGU;
    $numNU = $minIGNU;
    $filenameU = "$id.filtered_u_intergenicmappers.sam";
    $outfileU = "$id.intergenicmappers.norm_u.sam";
    $filenameNU = "$id.filtered_nu_intergenicmappers.sam";
    $outfileNU = "$id.intergenicmappers.norm_nu.sam";
    $dirU = $dirname . "/EIJ/Unique";
    $dirNU = $dirname . "/EIJ/NU";
    if (-e "$LOC/$dirU/$outfileU"){
	`rm $LOC/$dirU/$outfileU`;
    }
    if (-e "$LOC/$dirNU/$outfileNU"){
	`rm $LOC/$dirNU/$outfileNU`;
    }
    $shfileU = "$shdir/a" . $id . "intergenic.u_runshuf.sh";
    $shfileNU = "$shdir/a" . $id . "intergenic.nu_runshuf.sh";
    $lognameU = "$logdir/shuf.$id.intergenic.u";
    $lognameNU = "$logdir/shuf.$id.intergenic.nu";
    if($U eq 'true') {
	if (($total_lc ne '0') && ($numU ne '0')){
	    open(OUTFILEU, ">$shfileU");
	    print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
	    print OUTFILEU "echo \"got here\"\n";;
	    close(OUTFILEU);
	    while(qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU.out -e $lognameU.err < $shfileU`;
	}
    }
    if($NU eq 'true') {
	$for_lc =~ s/IGU/IGNU/g;
	$total_lc = $LINECOUNTS{$for_lc};
	if (($total_lc ne '0') && ($numNU ne '0')){
	    open(OUTFILENU, ">$shfileNU");
	    print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
	    print OUTFILENU "echo \"got here\"\n";
	    close(OUTFILENU);
	    while(qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU.out -e $lognameNU.err < $shfileNU`;
	}
    }
}
close(INFILE);

#exon_inconsistent reads
open(INFILE, $ARGV[0]);
while($dirname = <INFILE>) {
    chomp($dirname);
    $id = $dirname;
    $for_lc = "UND_U.$id";
    $total_lc = $LINECOUNTS{$for_lc};
    $numU = $minUND_U;
    $numNU = $minUND_NU;
    $filenameU = "$id.filtered_u_exon_inconsistent_reads.sam";
    $outfileU = "$id.exon_inconsistent_reads.norm_u.sam";
    $filenameNU = "$id.filtered_nu_exon_inconsistent_reads.sam";
    $outfileNU = "$id.exon_inconsistent_reads.norm_nu.sam";
    $dirU = $dirname . "/EIJ/Unique";
    $dirNU = $dirname . "/EIJ/NU";
    if (-e "$LOC/$dirU/$outfileU"){
        `rm $LOC/$dirU/$outfileU`;
    }
    if (-e "$LOC/$dirNU/$outfileNU"){
        `rm $LOC/$dirNU/$outfileNU`;
    }
    $shfileU = "$shdir/a" . $id . "exon_inconsistent_reads.u_runshuf.sh";
    $shfileNU = "$shdir/a" . $id . "exon_inconsistent_reads.nu_runshuf.sh";
    $lognameU = "$logdir/shuf.$id.exon_inconsistent_reads.u";
    $lognameNU = "$logdir/shuf.$id.exon_inconsistent_reads.nu";
    if($U eq 'true') {
        if (($total_lc ne '0') && ($numU ne '0')){
            open(OUTFILEU, ">$shfileU");
            print OUTFILEU "perl $path/run_shuf.pl $LOC/$dirU/$filenameU $total_lc $numU > $LOC/$dirU/$outfileU\n";
            print OUTFILEU "echo \"got here\"\n";;
            close(OUTFILEU);
            while(qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameU.out -e $lognameU.err < $shfileU`;
        }
    }
    if($NU eq 'true') {
        $for_lc =~ s/UND_U/UND_NU/g;
        $total_lc = $LINECOUNTS{$for_lc};
        if (($total_lc ne '0') && ($numNU ne '0')){
            open(OUTFILENU, ">$shfileNU");
            print OUTFILENU "perl $path/run_shuf.pl $LOC/$dirNU/$filenameNU $total_lc $numNU > $LOC/$dirNU/$outfileNU\n";
            print OUTFILENU "echo \"got here\"\n";
            close(OUTFILENU);
            while(qx{$status | wc -l} > $njobs){
                sleep(10);
            }
            `$submit $request_memory_option$mem $jobname_option $jobname -o $lognameNU.out -e $lognameNU.err < $shfileNU`;
        }
    }
}
close(INFILE);
print "got here\n";
