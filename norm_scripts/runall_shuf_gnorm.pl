#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE =  "\nUsage: perl runall_shuf_gnorm.pl <sample_dirs> <loc> [options]

where
<sample_dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs

will output the same number of rows from each file in <loc>/<dirs>/GNORM/Unique (same for NU) to NORMALIZED_DATA/GENE/Unique (and NU).

The output file names will be modified from the input file names.

** If  maximum line count is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

option:  
 -stranded : set this if the data are strand-specific.

 -u  :  set this if you want to return only unique mappers, otherwise by default it will return both unique and non-unique mappers

 -nu  :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-unique mappers

 -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.

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
my $stranded = "false";
my $status = "";
my $U = 'true';
my $NU = 'true';
my $numargs_u_nu = 0;
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $jobname_option = "";
my $numargs = 0;
my $se = "false";
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    my $option_u_nu = "false";
    if ($ARGV[$i] eq '-max_jobs'){
	$option_found = "true";
	$njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-se'){
	$option_found = "true";
	$se = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
        $option_found = "true";
        $stranded = "true";
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
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
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
my $path = abs_path($0);
$path =~ s/\/runall_shuf_gnorm.pl//;

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

my %LINECOUNTS_U;
my %LINECOUNTS_NU;
my %LINECOUNTS_U_A;
my %LINECOUNTS_NU_A;

my $MIN_U = 1000000000000;
my $MIN_NU = 1000000000000;
my $MIN_U_A = 1000000000000;
my $MIN_NU_A = 1000000000000;
if ($U eq 'true'){
    open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    while(my $line = <IN>){
	chomp($line);
	my $id = $line;
	my $cntinfo;
	if ($stranded eq "false"){
	    if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.linecount.txt"){
		$cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.linecount.txt`;
	    }
	    else{
		die "ERROR: The file '$LOC/$id/GNORM/Unique/$id.filtered_u.genes.linecount.txt' does not exist.\n";
	    }
	    my @c = split(/\t/, $cntinfo);
	    my $N = $c[1];
	    chomp($N);
	    $LINECOUNTS_U{$id} = $N;
	    if ($N < $MIN_U){
		$MIN_U = $N;
	    }
	}
	if ($stranded eq "true"){
	    if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.linecount.txt"){
		$cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.linecount.txt`;
            }
            else{
                die "ERROR: The file '$LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.linecount.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_U{$id} = $N;
            if ($N < $MIN_U){
                $MIN_U = $N;
            }
	    if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.linecount.txt"){
		$cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.linecount.txt`;
            }
            else{
                die "ERROR: The file '$LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.linecount.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_A{$id} = $N;
            if ($N < $MIN_U_A){
                $MIN_U_A = $N;
            }
	}
    }
    close(IN);
}
if ($NU eq 'true'){
    open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    while(my $line = <IN>){
	chomp($line);
        my $id = $line;
	my $cntinfo;
	if ($stranded eq "false"){
	    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.linecount.txt"){
		$cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.linecount.txt`;
	    }
	    else{
		die "ERROR: The file '$LOC/$id/GNORM/NU/$id.filtered_nu.genes.linecount.txt' does not exist.\n";
	    }
	    my @c = split(/\t/, $cntinfo);
	    my $N = $c[1];
	    chomp($N);
	    $LINECOUNTS_NU{$id} = $N;
	    if ($N < $MIN_NU){
		$MIN_NU = $N;
	    }
	}
	if ($stranded eq "true"){
	    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.linecount.txt"){
                $cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.linecount.txt`;
            }
            else{
                die "ERROR: The file '$LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.linecount.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU{$id} = $N;
            if ($N < $MIN_NU){
                $MIN_NU = $N;
            }
	    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.linecount.txt"){
                $cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.linecount.txt`;
            }
            else{
                die "ERROR: The file '$LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.linecount.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_A{$id} = $N;
            if ($N < $MIN_NU_A){
                $MIN_NU_A = $N;
            }
	}
    }
    close(IN);
}

##run shuf

open(INFILE, $ARGV[0]);
while(my $id = <INFILE>) {
    chomp($id);
    my $jobname = "$study.shuf_gnorm";
    if ($U eq "true"){
	if ($stranded eq "false"){
	    my $total_lc = $LINECOUNTS_U{$id};
	    my $filename_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.sam";
	    my $outfile_U = $filename_U;
	    $outfile_U =~ s/.sam$/.norm.sam/;
	    if (-e "$outfile_U"){
		`rm $outfile_U`;
	    }
	    my $shfile = "$shdir/run_shuf_gnorm_u.$id.sh";
	    my $logname = "$logdir/run_shuf_gnorm_u.$id";
	    if (($total_lc ne '0') && ($MIN_U ne '0')){
		open(OUTU, ">$shfile");
		if ($se eq "false"){
		    print OUTU "perl $path/run_shuf_gnorm.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
		}
		if ($se eq "true"){
		    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
		}
		print OUTU "echo \"got here\"\n";
		close(OUTU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
		sleep(2);
	    }
	}
	if ($stranded eq "true"){
	    my $total_lc = $LINECOUNTS_U{$id};
            my $filename_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.sam";
            my $outfile_U = $filename_U;
	    $outfile_U =~ s/.sam$/.norm.sam/;
            if (-e "$outfile_U"){
                `rm $outfile_U`;
            }
            my $shfile = "$shdir/run_shuf_gnorm_u.sense.$id.sh";
            my $logname = "$logdir/run_shuf_gnorm_u.sense.$id";
            if (($total_lc ne '0') && ($MIN_U ne '0')){
                open(OUTU, ">$shfile");
                if ($se eq "false"){
                    print OUTU "perl $path/run_shuf_gnorm.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
		}
                if ($se eq "true"){
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
		}
		print OUTU "echo \"got here\"\n";
                close(OUTU);
                while(qx{$status | wc -l} > $njobs){
                    sleep(10);
		}
                `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
		sleep(2);
            }
	    #antisense
	    my $total_lc_a = $LINECOUNTS_U_A{$id};
            my $filename_U_A = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.sam";
            my $outfile_U_A = $filename_U_A;
	    $outfile_U_A =~ s/.sam$/.norm.sam/;
            if (-e "$outfile_U_A"){
                `rm $outfile_U_A`;
            }
            my $shfile_a = "$shdir/run_shuf_gnorm_u.antisense.$id.sh";
            my $logname_a = "$logdir/run_shuf_gnorm_u.antisense.$id";
	    if (($total_lc_a ne '0') && ($MIN_U_A ne '0')){
		open(OUTU, ">$shfile_a");
                if ($se eq "false"){
                    print OUTU "perl $path/run_shuf_gnorm.pl $filename_U_A $total_lc_a $MIN_U_A > $outfile_U_A\n";
                }
                if ($se eq "true"){
                    print OUTU "perl $path/run_shuf.pl $filename_U_A $total_lc_a $MIN_U_A > $outfile_U_A\n";
                }
                print OUTU "echo \"got here\"\n";
                close(OUTU);
                while(qx{$status | wc -l} > $njobs){
                    sleep(10);
                }
                `$submit $request_memory_option$mem $jobname_option $jobname -o $logname_a.out -e $logname_a.err < $shfile_a`;
		sleep(2);
	    }
	}
    }
    if ($NU eq "true"){
	if ($stranded eq "false"){
	    my $total_lc = $LINECOUNTS_NU{$id};
	    my $filename_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.sam";
	    my $outfile_NU = $filename_NU;
	    $outfile_NU =~ s/.sam$/.norm.sam/;
	    if (-e "$outfile_NU"){
		`rm $outfile_NU`;
	    }
	    my $shfile = "$shdir/run_shuf_gnorm_nu.$id.sh";
	    my $logname = "$logdir/run_shuf_gnorm_nu.$id";
	    if (($total_lc ne '0') && ($MIN_NU ne '0')){
		open(OUTNU, ">$shfile");
		if ($se eq "false"){
		    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
		}
		if ($se eq "true"){
		    print OUTNU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
		}
		print OUTNU "echo \"got here\"\n";
		close(OUTNU);
		while(qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
		sleep(2);
	    }
	}
	if ($stranded eq "true"){
            my $total_lc = $LINECOUNTS_NU{$id};
            my $filename_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.sam";
            my $outfile_NU = $filename_NU;
	    $outfile_NU =~ s/.sam$/.norm.sam/;
	    if (-e "$outfile_NU"){
		`rm $outfile_NU`;
            }
            my $shfile = "$shdir/run_shuf_gnorm_nu.sense.$id.sh";
            my $logname = "$logdir/run_shuf_gnorm_nu.sense.$id";
            if (($total_lc ne '0') && ($MIN_NU ne '0')){
                open(OUTNU, ">$shfile");
                if ($se eq "false"){
                    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
		}
                if ($se eq "true"){
                    print OUTNU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
		}
                print OUTNU "echo \"got here\"\n";
                close(OUTNU);
                while(qx{$status | wc -l} > $njobs){
                    sleep(10);
		}
                `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
		sleep(2);
            }
	    #antisense
	    my $total_lc_a = $LINECOUNTS_NU_A{$id};
            my $filename_NU_A = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.sam";
            my $outfile_NU_A = $filename_NU_A;
	    $outfile_NU_A =~ s/.sam$/.norm.sam/;
            if (-e "$outfile_NU_A"){
                `rm $outfile_NU_A`;
            }
            my $shfile_a = "$shdir/run_shuf_gnorm_nu.antisense.$id.sh";
            my $logname_a = "$logdir/run_shuf_gnorm_nu.antisense.$id";
            if (($total_lc_a ne '0') && ($MIN_NU_A ne '0')){
		open(OUTNU, ">$shfile_a");
		if ($se eq "false"){
                    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU_A $total_lc_a $MIN_NU_A > $outfile_NU_A\n";
		}
                if ($se eq "true"){
                    print OUTNU "perl $path/run_shuf.pl $filename_NU_A $total_lc_a $MIN_NU_A > $outfile_NU_A\n";
		}
                print OUTNU "echo \"got here\"\n";
		close(OUTNU);
		while(qx{$status | wc -l} > $njobs){
                    sleep(10);
		}
                `$submit $request_memory_option$mem $jobname_option $jobname -o $logname_a.out -e $logname_a.err < $shfile_a`;
		sleep(2);
	    }
        }
    }
}
close(INFILE);
print "got here\n";
