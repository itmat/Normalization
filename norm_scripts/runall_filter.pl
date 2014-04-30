#!/usr/bin/env perl

$USAGE = "\nUsage: runall_filter.pl <file of sample dirs> <loc> <sam file name> [options]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<sam file name> is the name of sam file

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -se :  set this if the data is single end, otherwise by default it will assume it's a paired end data.

  -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

  -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

  -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_4G>\":
         set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
         **make sure the arguments are comma separated inside the quotes**

         <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
         <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
         <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
         <queue_name_for_4G> : is queue name for 4G (e.g. plus, 4G)

  -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 4G

  -h : print usage

This will remove all rows from input samfile except those that satisfy all of the following:
1. Unique mapper / NU mapper
2. Both forward and reverse map consistently
3. id not in (the appropriate) file specified in <more ids>
4. Only on a numbered chromosome, X or Y
5. Is a forward mapper (script outputs forward mappers only)

";
if(@ARGV < 3) {
    die $USAGE;
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_filter.pl//;
$sam_name = $ARGV[2];

$U = "true";
$NU = "true";
$numargs_1 = 0;
$pe = "true";

$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";

for($i=3; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$option_found = "true";
	$numargs_1++;
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs_1++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-se'){
        $pe = "false";
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
        $request_memory_option = "-q";
        $mem = "plus";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "4G";
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
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_4G>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_4G>\".\n";
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
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs_1 > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_4G>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

open(INFILE, $ARGV[0]);  # file of sample dirs (without path)
$LOC = $ARGV[1];  # the location where the sample dirs are
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$study = $fields[@fields-2];
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $id =~ s/\//_/g;
    $idsfile = "$LOC/$dir/$id.ribosomalids.txt";
    $shfile = "$shdir/a" . $id . "filter.sh";
    $jobname = "$study.filtersam";
    $logname = "$logdir/filtersam.$id";
    open(OUTFILE, ">$shfile");
    if ($numargs_1 eq "0"){
	if ($pe eq "true"){
	    print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile\n";
	}
	else {
	    print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -se \n";
	}
    }
    else {
	if($U eq "true") {
	    if ($pe eq "true"){
		print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -u\n";
	    }
	    else{
		print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -se -u\n";
	    }
	}
	if($NU eq "true") {
	    if ($pe eq "true"){
		print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -nu\n";
	    }
	    else{
		print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -se -nu\n";
	    }
	}
    }
    close(OUTFILE);
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
