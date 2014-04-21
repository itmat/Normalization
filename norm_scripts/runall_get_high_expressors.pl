#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_get_high_expressors.pl <sample dirs> <loc> <cutoff> <annotation file> <exons>[options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<cutoff> cutoff %
<annotation file> should be downloaded from UCSC known-gene track including
 at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, 
 spDisease, protein and gene fields from the Linked Tables table.
<exons> master list of exons file

option:
  -u  :  set this if you want to return only unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

  -nu :  set this if you want to return only non-unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other <submit> <jobname_option> <request_memory_option> <queue_name_for_15G>:
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_15G> : is queue name for 15G (e.g. max_mem30, 15G)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 15G

 -h : print usage

";
if(@ARGV<5) {
    die $USAGE;
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_get_high_expressors.pl//;

$U = "true";
$NU = "true";
$numargs_2 = 0;

$replace_mem = "false";
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
$numargs = 0;
for($i=5; $i<@ARGV; $i++) {
    $option_found = 'false';
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $option_found = "true";
        $numargs_2++;
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_2++;
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
        $mem = "max_mem30";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
        $mem = "15G";
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
            die "please provide <submit>, <jobname_option>, and <request_memory_option> <queue_name_for_15G>\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_15G>.\n";
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
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
        die $USAGE;
    }
    if($option_found eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs_2 > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_15G>.\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}


$LOC = $ARGV[1];
$LOC =~ s/\/$//;
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

$cutoff = $ARGV[2];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if (0 > $cutoff | 100 < $cutoff){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

$annot_file = $ARGV[3];
$exons = $ARGV[4];
$annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;
$master_sh = "$shdir/annotate_master_list_of_exons.sh";
$master_jobname = "$study.get_high_expressor";
$master_logname = "$logdir/masterexon.annotate";
open(OUTFILE, ">$master_sh");
print OUTFILE "perl $path/annotate.pl $annot_file $exons > $annotated_exons\n";
close(OUTFILE);
`$submit $jobname_option $master_jobname $request_memory_option$mem -o $master_logname.out -e $master_logname.err < $master_sh`;

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while($line = <INFILE>){
    chomp($line);
    $id = $line;
    $id =~ s/Sample_//;
    $sampledir = "$LOC/$line";
    $outfile = "$LOC/$line/$id.exonpercents.txt";
    $highfile = "$LOC/$line/$id.high_expressors.txt";
    $annotated = "$LOC/$line/$id.high_expressors_annot.txt";
    $shfile = "$shdir/$id.highexpressor.annotate.sh";
    $jobname = "$study.get_high_expressor";
    $logname = "$logdir/$id.highexpressor.annotate";
    open(OUT, ">$shfile");
    if ($numargs_2 eq "0"){
	print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile\n";
    }
    else { 
	if ($U eq "true"){
	    print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile -u \n";
	}
	if ($NU eq "true"){
	    print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile -nu \n";
	}
    }
    print OUT "perl $path/annotate.pl $annot_file $highfile > $annotated\n";
    print OUT "rm $highfile";
    close(OUT);
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);

