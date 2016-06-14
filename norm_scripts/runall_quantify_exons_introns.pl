#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl runall_exons_introns.pl <sample dirs> <loc> <exons> <introns> <intergenic regions>

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<exons> master list of exons file (full path)
<introns> master list of introns file (full path)
<intergenic regions> master list of intergenic regions file (full path)

* note : this script assumes the input samfile is single end data.

options:
 -exon_only : set this if you want to quantify exons only (this option does not work when -outputsam flag in use).
              By default, this script will output both exon and intronquants

 -intron_only : set this if you want to quantify exons only (this option does not work when -outputsam flag in use).
                By default, this script will output both exon and intronquants

 -filter_highexp : set this if you want to filter out the reads that map to highly expressed exons.

 -outputsam : set this if you want to output the sam files of exon mappers and notexonmappers.

 -depthE <n> : by default, it will output 20 exonmappers.

 -depthI <n> : by default, it will output 10 intronmappers.

 -str_f : set this if the data are strand-specific AND forward read is in the same orientation as the transcripts/genes.

 -str_r : set this if the data are strand-specific AND reverse read is in the same orientation as the transcripts/genes.

 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -norm <s> : set this to get genes file for the gene-normalized sam files.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_6G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. 6144, 6G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -i <n> : index for logname (default: 0)

 -h : print usage


";


if (@ARGV < 5){
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_quantify_exons_introns.pl//;
my $norm = "false";
my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $status;
my $orientation = "";
my $str_args = 0;
my $stranded = "false";
my $i_exon = 20;
my $i_intron = 10;
my $print = "";
my $outputsam = "false";
my $filter = "";
my $qinfo = "";
my $qcnt = 0;
my $index = 0;
my $normdir = "";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=5; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-i'){
        $option_found = "true";
        $index = $ARGV[$i+1];
        if ($index !~ /(\d+$)/ ){
            die "-i <n> : <n> needs to be a number\n";
        }
        $i++;
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
    if ($ARGV[$i] eq '-exon_only'){
        $option_found = "true";
        $qinfo = "-exon_only";
	$qcnt++;
    }
    if ($ARGV[$i] eq '-intron_only'){
        $option_found = "true";
        $qinfo = "-intron_only";
	$qcnt++;
    }
    if ($ARGV[$i] eq '-outputsam'){
	$option_found = "true";
	$outputsam = "true";
	$print = "-outputsam";
    }
    if ($ARGV[$i] eq '-filter_highexp'){
	$option_found = "true";
	$filter = "-filter_highexp";
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq "-norm"){
        $norm = "true";
        $option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq "-str_f"){
        $orientation = "-str_f";
	$stranded = "true";
        $option_found = "true";
        $str_args++;
    }
    if ($ARGV[$i] eq "-str_r"){
        $orientation = "-str_r";
	$stranded = "true";
        $option_found = "true";
        $str_args++;
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_u_nu++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-M";
	$mem="6144";
        $status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
	$mem="6G";
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
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $status eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_6G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_6G>,<status>\".\n";
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
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}

if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}
if($numargs_u_nu > 1) {
    die "you cannot use both -u and -nu\n.
";
}
if ($stranded eq "true"){
    if ($str_args ne '1'){
        die "please specify read orientation of stranded data: -str_f or -str_r\n";
    }
}

if ($qcnt > 1){
    die "You cannot use both -exon_only and -intron_only. It will quantify both exons and introns by default.\n\n";
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

my $exons = $ARGV[2];
my $introns = $ARGV[3];
my $igs = $ARGV[4];
my $norm_dir = "$normdir/EXON_INTRON_JUNCTION/FINAL_SAM";
open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames;
while(my $line = <IN>){
    my ($filename_u, $filename_nu, $shfile_u, $shfile_nu, $logname_u, $logname_nu);
    my ($filename_exon, $filename_intron, $shfile_exon, $shfile_intron, $logname_exon, $logname_intron);
    chomp($line);
    my $id = $line;
    my $eij_dir = "$LOC/$id/EIJ";
    my $jobname = "$study.quantify_exons_introns";
    if ($norm eq "false"){
	$filename_u = "$eij_dir/Unique/$id.filtered_u.sam";
	$filename_nu = "$eij_dir/NU/$id.filtered_nu.sam";
	$shfile_u = "$shdir/Q.$id.quantify_exons_introns_u.sh";
	$logname_u = "$logdir/quantify_exons_introns_u";
	$shfile_nu = "$shdir/Q.$id.quantify_exons_introns_nu.sh";
	$logname_nu = "$logdir/quantify_exons_introns_nu";
	if ($outputsam eq "true"){
	    $qinfo = "";
	    $shfile_u =~ s/.sh$/.outputsam.sh/g;
	    $shfile_nu =~ s/.sh$/.outputsam.sh/g;
	    $logname_u = "$logdir/quantify_exons_introns.outputsam.$index.u";
	    $logname_nu = "$logdir/quantify_exons_introns.outputsam.$index.nu";
	}
	$logname_u = $logname_u . ".$id";
	$logname_nu = $logname_nu . ".$id";
	if ($U eq "true"){
	    open(OUT, ">$shfile_u");
	    print OUT "perl $path/quantify_exons_introns.pl $filename_u $exons $introns $igs $LOC $filter $print -depthE $i_exon -depthI $i_intron $orientation $qinfo\n";
	    close(OUT);
	    while(qx{$status | wc -l}>$njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_u.out -e $logname_u.err < $shfile_u`;
	}
	if ($NU eq "true"){
	    open(OUT, ">$shfile_nu");
	    print OUT "perl $path/quantify_exons_introns.pl $filename_nu $exons $introns $igs $LOC $filter $print -depthE $i_exon -depthI $i_intron $orientation $qinfo \n";
	    close(OUT);
	    while(qx{$status | wc -l}>$njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_nu.out -e $logname_nu.err < $shfile_nu`;
	}
    }

    if ($norm eq "true"){
	if ($stranded eq "false"){
	    $filename_exon = "$norm_dir/exonmappers/$id.exonmappers.norm.sam";
	    $filename_intron = "$norm_dir/intronmappers/$id.intronmappers.norm.sam";
	    $shfile_exon = "$shdir/Q.$id.quantify_exons_introns.2.exon.sh";
	    $shfile_intron = "$shdir/Q.$id.quantify_exons_introns.2.intron.sh";
	    $logname_exon = "$logdir/quantify_exons_introns.2.$id.exon";
	    $logname_intron = "$logdir/quantify_exons_introns.2.$id.intron";
	    #exonquants
	    $qinfo = "-exon_only";
	    open(OUT, ">$shfile_exon");
	    print OUT "perl $path/quantify_exons_introns.pl $filename_exon $exons $introns $igs $LOC $orientation $qinfo $filter\n";
	    close(OUT);
	    while(qx{$status | wc -l}>$njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_exon.out -e $logname_exon.err < $shfile_exon`;
	    #intronquants
	    $qinfo = "-intron_only";
	    open(OUT, ">$shfile_intron");
	    print OUT "perl $path/quantify_exons_introns.pl $filename_intron $exons $introns $igs $LOC $orientation $qinfo $filter\n";
	    close(OUT);
	    while(qx{$status | wc -l}>$njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_intron.out -e $logname_intron.err < $shfile_intron`;
	}
	if ($stranded eq "true"){
	    my $filename_exon_s = "$norm_dir/exonmappers/sense/$id.exonmappers.norm.sam";
            my $filename_intron_s = "$norm_dir/intronmappers/sense/$id.intronmappers.norm.sam";
	    my $filename_exon_a = "$norm_dir/exonmappers/antisense/$id.exonmappers.norm.sam";
            my $filename_intron_a = "$norm_dir/intronmappers/antisense/$id.intronmappers.norm.sam";
            my $shfile_exon_s = "$shdir/Q.$id.quantify_exons_introns.2.exon_sense.sh";
            my $shfile_exon_a = "$shdir/Q.$id.quantify_exons_introns.2.exon_antisense.sh";
            my $shfile_intron_s = "$shdir/Q.$id.quantify_exons_introns.2.intron_sense.sh";
            my $shfile_intron_a = "$shdir/Q.$id.quantify_exons_introns.2.intron_antisense.sh";
            my $logname_exon_s = "$logdir/quantify_exons_introns.2.$id.exon_sense";
            my $logname_exon_a = "$logdir/quantify_exons_introns.2.$id.exon_antisense";
            my $logname_intron_s = "$logdir/quantify_exons_introns.2.$id.intron_sense";
            my $logname_intron_a = "$logdir/quantify_exons_introns.2.$id.intron_antisense";
            #exonquants
            $qinfo = "-exon_only";
	    #sense
            open(OUT, ">$shfile_exon_s");
            print OUT "perl $path/quantify_exons_introns.pl $filename_exon_s $exons $introns $igs $LOC $orientation $qinfo $filter\n";
            close(OUT);
            while(qx{$status | wc -l}>$njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_exon_s.out -e $logname_exon_s.err < $shfile_exon_s`;
	    #antisense
	    open(OUT, ">$shfile_exon_a");
            print OUT "perl $path/quantify_exons_introns.pl $filename_exon_a $exons $introns $igs $LOC $orientation $qinfo $filter\n";
            close(OUT);
            while(qx{$status | wc -l}>$njobs){
		sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_exon_a.out -e $logname_exon_a.err < $shfile_exon_a`;
            #intronquants
            $qinfo = "-intron_only";
	    #sense
            open(OUT, ">$shfile_intron_s");
            print OUT "perl $path/quantify_exons_introns.pl $filename_intron_s $exons $introns $igs $LOC $orientation $qinfo $filter\n";
            close(OUT);
            while(qx{$status | wc -l}>$njobs){
                sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_intron_s.out -e $logname_intron_s.err < $shfile_intron_s`;
            #antisense
            open(OUT, ">$shfile_intron_a");
            print OUT "perl $path/quantify_exons_introns.pl $filename_intron_a $exons $introns $igs $LOC $orientation $qinfo $filter\n";
            close(OUT);
            while(qx{$status | wc -l}>$njobs){
		sleep(10);
            }
            `$submit $jobname_option $jobname $request_memory_option$mem -o $logname_intron_a.out -e $logname_intron_a.err < $shfile_intron_a`;
	}
    }
}
close(IN);
print "got here\n";



