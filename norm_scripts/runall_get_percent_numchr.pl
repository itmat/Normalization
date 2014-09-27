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

 -other \"<submit>,<jobname_option>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

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
my $status;
my $njobs = 200;
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
    }
    if ($ARGV[$i] eq '-EIJ'){
	$eij = "true";
	$numargs++;
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_c++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs_c++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs_c++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
	$status = $a[2];
        $i++;
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<status>\".\n";
        }
    }
}
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<status>\".\n
";
}
if ($numargs ne '1'){
    die "you have to specify what type of normalization you're running. choose -GENE or -EIJ \n\n";
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
    `$submit $jobname_option $jobname -o $logdir/$logname.out -e $logdir/$logname.err < $sh`;
}
close(IN);

print "got here\n";    


