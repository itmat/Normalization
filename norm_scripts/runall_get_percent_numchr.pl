use warnings;
use strict;

my $USAGE = "perl runall_get_percent_numchr.pl <sample dirs> <loc>

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

options:
 -GENE: set this if you're running GENE normalization

 -EIJ: set this if you're running EXON-INTRON-JUNCTION normalization

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\":
         set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
         **make sure the arguments are comma separated inside the quotes**

         <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
         <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
         <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
         <queue_name_for_3G> : is queue name for 3G (e.g. 3072, 3G)
         <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 3G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.

 -h : print usage

";

if (@ARGV < 2){
    die $USAGE;
}

my $gnorm = "false";
my $eij = "false";
my $numargs = 0;
my $numargs_c = 0;
my $submit;
my $jobname_option;
my $request_memory_option;
my $mem;
my $status;
my $njobs = 200;
my $new_mem;
my $replace_mem = "false";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-GENE'){
	$gnorm = "true";
	$numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-EIJ'){
	$eij = "true";
	$numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_c++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-M";
	$mem = "3072";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs_c++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
	$mem = "3G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs_c++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""| $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_3G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n";
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
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_3G>,<status>\".\n
";
}
if ($numargs ne '1'){
    die "you have to specify what type of normalization you're running. choose -GENE or -EIJ \n\n";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}
my $dirs = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_get_percent_numchr.pl//;

open(IN, $dirs);
while(my $line = <IN>){
    chomp($line);
    my ($sam, $sh, $logname, $jobname, $out);
    if ($eij eq "true"){
	$sam = "$LOC/$line/EIJ/Unique/$line.filtered_u.sam";
	$sh = "$shdir/numchrcnt.$line.sh";
	$logname = "numchrcnt.$line";
	$jobname = "$study.numchrcnt";
    }
    if ($gnorm eq "true"){
	$sam = "$LOC/$line/GNORM/Unique/$line.filtered_u.sam";
        $sh = "$shdir/numchrcnt_gnorm.$line.sh";
        $logname = "numchrcnt_gnorm.$line";
	$jobname = "$study.numchrcnt_gnorm";
    }
    $out = $sam;
    $out =~ s/.sam$/.numchr_count.txt/;
    open(OUT, ">$sh");
    print OUT "perl $path/get_percent_numchr.pl $sam $out\n";
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $request_memory_option$mem $jobname_option $jobname -o $logdir/$logname.out -e $logdir/$logname.err < $sh`;
    sleep(2);
}
close(IN);

print "got here\n";    


