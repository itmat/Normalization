use warnings;
use strict;

my $USAGE = "\nperl runall_check_samformat.pl <sample_dirs> <loc> <samfilename>

 -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.

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

 -bam <samtools>: baminput

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";

if (@ARGV<3){
    die $USAGE;
}
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $status;
my $numargs_c = 0;
my $cnt_st = 0;
my $seoption = "";
my $b_option = "";
for (my $i=3;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-se'){
        $seoption = "-se";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-bam'){
        $b_option = "-bam $ARGV[$i+1]";
        $option_found = "true";
	$i++;
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
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
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq ""
	    | $mem eq ""| $status eq ""){
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
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

my $LOC = $ARGV[1];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;
}
unless (-d $logdir){
    `mkdir $logdir`;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_check_samformat.pl//;
my $filename = $ARGV[2];

open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'";
while(my $line = <IN>){
    chomp($line);
    my $samfile;
    $samfile = "$LOC/$line/$filename";
    my $shfile = "$shdir/check_samformat.$line.sh";
    my $jobname = "$study.check_samformat";
    my $logname = "$logdir/check_samformat.$line";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path/check_samformat.pl $samfile $seoption $b_option\n";
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x = `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
    sleep(2);
}
close(IN);
print "got here\n";
