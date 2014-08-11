#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl runall_quantify_genes.pl <sample dirs> <loc> <ensGene file>

<sample dirs> is  a file of sample directories with alignment output wi
thout path
<loc> is where the sample directories are
<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

option:
 -u  :  set this if your final (normalized) sam files have unique mappers only.
        otherwise by default it will use merged(unique+non-unique) mappers.

 -nu  :  set this if your final (normalized) sam files have non-unique mappers only.
         otherwise by default it will use merged(unique+non-unique) mappers.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.

 -h : print usage

\n";

if (@ARGV < 3){
    die $USAGE
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_quantify_genes.pl//;

my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $submit = "";
my $jobname_option = "";
my $status;
for (my $i=3; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
	$i++;
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
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
	$option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
        my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $status = $a[2];
        $i++;
	$i++;
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $status eq ""){
            die "please provide \"<submit>, <jobname_option>, and <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname\
_option> ,<status>\".\n";
        }
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,\
<status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu\n.
";
}




my $samples = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $norm_dir = $study_dir . "NORMALIZED_DATA";
my $finalsam_dir = $norm_dir . "/FINAL_SAM";
my $final_U_dir = "$finalsam_dir/Unique";
my $final_NU_dir = "$finalsam_dir/NU";
my $final_M_dir = "$finalsam_dir/MERGED";
my $ensFile = $ARGV[2];
my %ID;

open(ENS, $ensFile) or die "cannot find file \"$ensFile\"\n";
my $header = <ENS>;
chomp($header);
my @ENSHEADER = split(/\t/, $header);
my ($genenamecol, $genesymbolcol);
for(my $i=0; $i<@ENSHEADER; $i++){
    if ($ENSHEADER[$i] =~ /.name2$/){
        $genenamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /.ensemblToGeneName.value$/){
        $genesymbolcol = $i;
    }
}
if (!defined($genenamecol) || !defined($genesymbolcol)){
    die "Your header must contain columns with the following suffixes: name2, ensemblToGeneName.value\n";
}
while(my $line = <ENS>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $geneid = $a[$genenamecol];
    my $genesym = $a[$genesymbolcol];
    $ID{$geneid}= $genesym;
}
close(ENS);

my $master_list_of_genes = "$LOC/master_list_of_ensGeneIDs.txt";
open(MAS, ">$master_list_of_genes");
foreach my $key (keys %ID){
    print MAS "$key\t$ID{$key}\n";
}
close(MAS);

open(IN, $samples) or die "cannot find file '$samples'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my ($filename, $outname);
    if ($numargs_u_nu eq '0'){
        $filename = "$final_M_dir/$id.FINAL.norm.genes.txt";
    }
    elsif ($U eq 'true'){
        $filename = "$final_U_dir/$id.FINAL.norm_u.genes.txt";
    }
    elsif ($NU eq 'true'){
        $filename = "$final_NU_dir/$id.FINAL.norm_nu.genes.txt";
    }
    $outname = $filename;
    $outname =~ s/genes.txt/genequants/g;
    my $shfile = "$shdir/GQ.$id.quantifygenes.sh";
    my $jobname = "$study.quantifygenes";
    my $logname = "$logdir/quantifygenes.$id";

    open(OUT, ">$shfile");
    print OUT "perl $path/quantify_genes.pl $filename $master_list_of_genes $outname\n";
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
        sleep(10);
    }
    `$submit $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;

}
close(IN);
print "got here\n";
