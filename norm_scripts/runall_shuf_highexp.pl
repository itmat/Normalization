#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE =  "\nUsage: perl runall_shuf_highexp.pl <sample_dirs> <loc> [options]

where
<sample_dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs

The output file names will be modified from the input file names.

** If  maximum line count is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

option:  
 -stranded : set this if the data are strand-specific.

 -u  :  set this if you want to return only unique mappers, otherwise by default it will return both unique and non-unique mappers

 -nu  :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-unique mappers

 -depthExon <n>:
 
 -depthIntron <n>: 

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

 -alt_stats <s>

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
my $i_exon = 20;
my $i_intron = 10;
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = "$study_dir/STATS";

for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    my $option_u_nu = "false";
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-depthExon'){
        $i_exon = $ARGV[$i+1];
        $i++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-depthIntron'){
        $i_intron = $ARGV[$i+1];
        $i++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-max_jobs'){
	$option_found = "true";
	$njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
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
$path =~ s/\/runall_shuf_highexp.pl//;

my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $lcdir = "$stats_dir/lineCounts";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
unless(-d $lcdir){
    `cp -r $study_dir/STATS/lineCounts $stats_dir/`;
}

my %HIGH_EX;
my %HIGH_EX_A;
my %HIGH_INT;
my %HIGH_INT_A;

my ($highexp_e_a, $highexp_i_a);
my $highexp_e = "$LOC/high_expressers_exon.txt";
my $highexp_i = "$LOC/high_expressers_intron.txt";
if ($stranded eq "true"){
    $highexp_e = "$LOC/high_expressers_exon_sense.txt";
    $highexp_i = "$LOC/high_expressers_intron_sense.txt";
    $highexp_e_a = "$LOC/high_expressers_exon_antisense.txt";
    $highexp_i_a = "$LOC/high_expressers_intron_antisense.txt";
}
open(INFILE, $highexp_e) or die "cannot find \"$highexp_e\"\n";
while (my $line = <INFILE>){
    chomp($line);
    $HIGH_EX{$line} = 1;
}
close(INFILE);
open(IN, $highexp_i) or die "cannot find \"$highexp_i\"\n";
while (my $line = <IN>){
    chomp($line);
    $HIGH_INT{$line} = 1;
}
close(IN);
if ($stranded eq "true"){
    open(INFILE, $highexp_e_a) or die "cannot find \"$highexp_e_a\"\n";
    while (my $line = <INFILE>){
	chomp($line);
	$HIGH_EX_A{$line} = 1;
    }
    close(INFILE);
    open(IN, $highexp_i_a) or die "cannot find \"$highexp_i_a\"\n";
    while (my $line = <IN>){
	chomp($line);
	$HIGH_INT_A{$line} = 1;
    }
    close(IN);
}
my $cntE = keys %HIGH_EX;
my $cntI = keys %HIGH_INT;
my $cntEA = keys %HIGH_EX_A;
my $cntIA = keys %HIGH_INT_A;
if (($cntE eq 0) && ($cntI eq 0) && ($cntEA eq 0) && ($cntIA eq 0)){
    my $lntemp = "$logdir/run_shuf_highexp_u.temp";
    my $lntemp_nu = "$logdir/run_shuf_highexp_nu.temp";
    `touch $lntemp.err $lntemp_nu.err`;
    `echo "got here" > $lntemp.out`;
    `echo "got here" > $lntemp_nu.out`;
}
my $LINECOUNTS_U_E = 0;
my $LINECOUNTS_NU_E = 0;
my $LINECOUNTS_U_A_E = 0;
my $LINECOUNTS_NU_A_E = 0;
my $LINECOUNTS_U_I = 0;
my $LINECOUNTS_NU_I = 0;
my $LINECOUNTS_U_A_I = 0;
my $LINECOUNTS_NU_A_I = 0;
if ($U eq 'true'){
    for (my $i=1; $i<=$i_exon;$i++){
	my $cntinfo;
	if ($stranded eq "false"){
	    if (-e "$lcdir/exon.unique.lc.$i.txt"){
		$cntinfo = `sort -nk 2 $lcdir/exon.unique.lc.$i.txt | head -1`;
	    }
	    else{
		die "ERROR: The file '$lcdir/exon.unique.lc.$i.txt' does not exist.\n";
	    }
	    my @c = split(/\t/, $cntinfo);
	    my $N = $c[1];
	    chomp($N);
	    $LINECOUNTS_U_E += $N;
	}
	if ($stranded eq "true"){
	    #sense
	    if (-e "$lcdir/exon.unique.sense.lc.$i.txt"){
		$cntinfo = `sort -nk 2 $lcdir/exon.unique.sense.lc.$i.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/exon.unique.sense.lc.$i.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_E += $N;
	    #antisense
            if (-e "$lcdir/exon.unique.antisense.lc.$i.txt"){
                $cntinfo = `sort -nk 2 $lcdir/exon.unique.antisense.lc.$i.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/exon.unique.antisense.lc.$i.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_A_E += $N;
	}
    }
    for (my $j=1; $j<=$i_intron;$j++){
	my $cntinfo;
        if ($stranded eq "false"){
            if (-e "$lcdir/intron.unique.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.unique.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.unique.lc.$j.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_I += $N;
        }
	if ($stranded eq "true"){
	    #sense
            if (-e "$lcdir/intron.unique.sense.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.unique.sense.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.unique.sense.lc.$j.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_I += $N;
	    #antisense
            if (-e "$lcdir/intron.unique.antisense.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.unique.antisense.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.unique.antisense.lc.$j.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_U_A_I += $N;
	}
    }
}
if ($NU eq 'true'){
    for (my $i=1; $i<=$i_exon;$i++){
        my $cntinfo;
        if ($stranded eq "false"){
            if (-e "$lcdir/exon.nu.lc.$i.txt"){
                $cntinfo = `sort -nk 2 $lcdir/exon.nu.lc.$i.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/exon.nu.lc.$i.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_E += $N;
        }
        if ($stranded eq "true"){
	    #sense
            if (-e "$lcdir/exon.nu.sense.lc.$i.txt"){
                $cntinfo = `sort -nk 2 $lcdir/exon.nu.sense.lc.$i.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/exon.nu.sense.lc.$i.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_E += $N;
            #antisense
            if (-e "$lcdir/exon.nu.antisense.lc.$i.txt"){
                $cntinfo = `sort -nk 2 $lcdir/exon.nu.antisense.lc.$i.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/exon.nu.antisense.lc.$i.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_A_E += $N;
	}
    }

    for (my $j=1; $j<=$i_intron;$j++){
        my $cntinfo;
        if ($stranded eq "false"){
            if (-e "$lcdir/intron.nu.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.nu.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.nu.lc.$j.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_I += $N;
        }
        if ($stranded eq "true"){
	    #sense
            if (-e "$lcdir/intron.nu.sense.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.nu.sense.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.nu.lc.sense.$j.txt' does not exist.\n";
            }
            my @c = split(/\t/, $cntinfo);
            my $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_I += $N;
	    #sense
            if (-e "$lcdir/intron.nu.antisense.lc.$j.txt"){
                $cntinfo = `sort -nk 2 $lcdir/intron.nu.antisense.lc.$j.txt | head -1`;
            }
            else{
                die "ERROR: The file '$lcdir/intron.nu.lc.antisense.$j.txt' does not exist.\n";
            }
            @c = split(/\t/, $cntinfo);
            $N = $c[1];
            chomp($N);
            $LINECOUNTS_NU_A_I += $N;
        }
    }
}

#print "UEXON:$LINECOUNTS_U_E\nNUEXON:$LINECOUNTS_NU_E\nUINT:$LINECOUNTS_U_I\nNUINT:$LINECOUNTS_NU_I\n"; #debug

#generate matrix

#solve matrix




##run shuf
open(INFILE, $ARGV[0]);
while(my $id = <INFILE>) {
    chomp($id);
    my $jobname = "$study.shuf_highexp";
    if ($U eq "true"){
	if ($stranded eq "false"){
	    my $ep_u = "$LOC/$id/$id.exonpercents.txt";
	    my $ip_u = "$LOC/$id/$id.intronpercents.txt";
	    my $cntinfo;
	    foreach my $exon (keys %HIGH_EX){
		my $total_lc = 0;
		my $tmpname = $exon;
		$tmpname =~ s/:/./;
		my $line = `grep -w $exon $ep_u`;
		my @p = split(/\t/, $line);
		my $N = $p[1];
		chomp($N);
		my $MIN_U = int(($LINECOUNTS_U_E * $N) / 100);
		if (-e "$LOC/$id/EIJ/Unique/linecounts.txt"){
		    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/linecounts.txt`;
		}
		my @c = split(/\t/, $cntinfo);
		$N = $c[1];
		chomp($N);
		$total_lc = $N;
		my $filename_U = "$LOC/$id/EIJ/Unique/$id.filtered_u_exonmappers.$tmpname.sam";
		my $outfile_U = $filename_U;
		$outfile_U =~ s/.sam$/.highexp.sam/i;
		if (-e "$outfile_U"){
		    `rm $outfile_U`;
		}
		my $shfile = "$shdir/run_shuf_u_highexp.$id.$tmpname.sh";
		my $logname = "$logdir/run_shuf_highexp_u.$id.$tmpname";
		if (($total_lc ne '0') && ($MIN_U ne '0')){
		    open(OUTU, ">$shfile");
		    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
		    print OUTU "echo \"got here\"\n";
		    close(OUTU);
		    while(qx{$status | wc -l} > $njobs){
			sleep(10);
		    }
		    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
		    sleep(2);
		}
	    }
            foreach my $intron (keys %HIGH_INT){
                my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_u`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_U = int(($LINECOUNTS_U_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/Unique/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_U = "$LOC/$id/EIJ/Unique/$id.filtered_u_intronmappers.$tmpname.sam";
                my $outfile_U = $filename_U;
                $outfile_U =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_U"){
                    `rm $outfile_U`;
                }
                my $shfile = "$shdir/run_shuf_u_highexp.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_u.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_U ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
	    }
	}
	if ($stranded eq "true"){
	    my $ep_u = "$LOC/$id/$id.exonpercents_sense.txt";
	    my $ep_u_a = "$LOC/$id/$id.exonpercents_antisense.txt";
	    my $cntinfo;
	    #sense exon
            foreach my $exon (keys %HIGH_EX){
                my $total_lc = 0;
                my $tmpname = $exon;
                $tmpname =~ s/:/./;
                my $line = `grep -w $exon $ep_u`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_U = int(($LINECOUNTS_U_E * $N) / 100);
                if (-e "$LOC/$id/EIJ/Unique/sense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/sense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_U = "$LOC/$id/EIJ/Unique/sense/$id.filtered_u_exonmappers.$tmpname.sam";
                my $outfile_U = $filename_U;
                $outfile_U =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_U"){
                    `rm $outfile_U`;
                }
                my $shfile = "$shdir/run_shuf_u_highexp.sense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_u.sense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_U ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
	    }
	    #antisense exon
            foreach my $exon (keys %HIGH_EX_A){
                my $total_lc = 0;
                my $tmpname = $exon;
                $tmpname =~ s/:/./;
                my $line = `grep -w $exon $ep_u_a`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_U = int(($LINECOUNTS_U_A_E * $N) / 100);
                if (-e "$LOC/$id/EIJ/Unique/antisense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/antisense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_U = "$LOC/$id/EIJ/Unique/antisense/$id.filtered_u_exonmappers.$tmpname.sam";
                my $outfile_U = $filename_U;
                $outfile_U =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_U"){
                    `rm $outfile_U`;
                }
                my $shfile = "$shdir/run_shuf_u_highexp.antisense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_u.antisense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_U ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
		    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
	    }
	    my $ip_u = "$LOC/$id/$id.intronpercents_sense.txt";
	    my $ip_u_a = "$LOC/$id/$id.intronpercents_antisense.txt";
	    #sense intron
            foreach my $intron (keys %HIGH_INT){
                my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_u`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_U = int(($LINECOUNTS_U_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/Unique/sense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/sense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_U = "$LOC/$id/EIJ/Unique/sense/$id.filtered_u_intronmappers.$tmpname.sam";
                my $outfile_U = $filename_U;
                $outfile_U =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_U"){
                    `rm $outfile_U`;
                }
                my $shfile = "$shdir/run_shuf_u_highexp.sense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_u.sense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_U ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
	    #antisense intron
            foreach my $intron (keys %HIGH_INT_A){
                my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_u_a`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_U = int(($LINECOUNTS_U_A_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/Unique/antisense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/Unique/antisense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_U = "$LOC/$id/EIJ/Unique/antisense/$id.filtered_u_intronmappers.$tmpname.sam";
                my $outfile_U = $filename_U;
                $outfile_U =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_U"){
                    `rm $outfile_U`;
                }
                my $shfile = "$shdir/run_shuf_u_highexp.antisense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_u.antisense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_U ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $MIN_U > $outfile_U\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
	}
    }
    if ($NU eq "true"){
	if ($stranded eq "false"){
	    my $ep_nu = "$LOC/$id/$id.exonpercents.nu.txt";
	    my $ip_nu = "$LOC/$id/$id.intronpercents.nu.txt";
	    my $cntinfo;
	    foreach my $exon (keys %HIGH_EX){
		my $total_lc = 0;
		my $tmpname = $exon;
		$tmpname =~ s/:/./;
		my $line = `grep -w $exon $ep_nu`;
		my @p = split(/\t/, $line);
		my $N = $p[1];
		chomp($N);
		my $MIN_NU = int(($LINECOUNTS_NU_E * $N) / 100);
		if (-e "$LOC/$id/EIJ/NU/linecounts.txt"){
		    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/linecounts.txt`;
		}
		my @c = split(/\t/, $cntinfo);
		$N = $c[1];
		chomp($N);
		$total_lc = $N;
		my $filename_NU = "$LOC/$id/EIJ/NU/$id.filtered_nu_exonmappers.$tmpname.sam";
		my $outfile_NU = $filename_NU;
		$outfile_NU =~ s/.sam$/.highexp.sam/i;
		if (-e "$outfile_NU"){
			`rm $outfile_NU`;
		}
                my $shfile = "$shdir/run_shuf_nu_highexp.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
	    foreach my $intron (keys %HIGH_INT){
		my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_nu`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_NU = int(($LINECOUNTS_NU_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/NU/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
		$total_lc = $N;
                my $filename_NU = "$LOC/$id/EIJ/NU/$id.filtered_nu_intronmappers.$tmpname.sam";
                my $outfile_NU = $filename_NU;
                $outfile_NU =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_NU"){
                    `rm $outfile_NU`;
                }
		my $shfile = "$shdir/run_shuf_nu_highexp.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
	    }
	}
	if ($stranded eq "true"){
	    my $ip_nu = "$LOC/$id/$id.intronpercents.nu_sense.txt";
	    my $ip_nu_a = "$LOC/$id/$id.intronpercents.nu_antisense.txt";
	    my $ep_nu = "$LOC/$id/$id.exonpercents.nu_sense.txt";
	    my $ep_nu_a = "$LOC/$id/$id.exonpercents.nu_antisense.txt";
	    my $cntinfo;
	    #sense exon
            foreach my $exon (keys %HIGH_EX){
                my $total_lc = 0;
                my $tmpname = $exon;
                $tmpname =~ s/:/./;
                my $line = `grep -w $exon $ep_nu`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_NU = int(($LINECOUNTS_NU_E * $N) / 100);
                if (-e "$LOC/$id/EIJ/NU/sense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/sense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_NU = "$LOC/$id/EIJ/NU/sense/$id.filtered_nu_exonmappers.$tmpname.sam";
                my $outfile_NU = $filename_NU;
                $outfile_NU =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_NU"){
		    `rm $outfile_NU`;
                }
                my $shfile = "$shdir/run_shuf_nu_highexp.sense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.sense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
            #antisense exon
            foreach my $exon (keys %HIGH_EX_A){
                my $total_lc = 0;
                my $tmpname = $exon;
                $tmpname =~ s/:/./;
                my $line = `grep -w $exon $ep_nu_a`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_NU = int(($LINECOUNTS_NU_A_E * $N) / 100);
                if (-e "$LOC/$id/EIJ/NU/antisense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/antisense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_NU = "$LOC/$id/EIJ/NU/antisense/$id.filtered_nu_exonmappers.$tmpname.sam";
                my $outfile_NU = $filename_NU;
                $outfile_NU =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_NU"){
                    `rm $outfile_NU`;
                }
                my $shfile = "$shdir/run_shuf_nu_highexp.antisense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.antisense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
	    #sense intron
            foreach my $intron (keys %HIGH_INT){
                my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_nu`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_NU = int(($LINECOUNTS_NU_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/NU/sense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/sense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_NU = "$LOC/$id/EIJ/NU/sense/$id.filtered_nu_intronmappers.$tmpname.sam";
                my $outfile_NU = $filename_NU;
                $outfile_NU =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_NU"){
                    `rm $outfile_NU`;
                }
                my $shfile = "$shdir/run_shuf_nu_highexp.sense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.sense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }       
	    #antisense intron
            foreach my $intron (keys %HIGH_INT_A){
                my $total_lc = 0;
                my $tmpname = $intron;
                $tmpname =~ s/:/./;
                my $line = `grep -w $intron $ip_nu_a`;
                my @p = split(/\t/, $line);
                my $N = $p[1];
                chomp($N);
                my $MIN_NU = int(($LINECOUNTS_NU_A_I * $N) / 100);
                if (-e "$LOC/$id/EIJ/NU/antisense/linecounts.txt"){
                    $cntinfo = `grep $tmpname $LOC/$id/EIJ/NU/antisense/linecounts.txt`;
                }
                my @c = split(/\t/, $cntinfo);
                $N = $c[1];
                chomp($N);
                $total_lc = $N;
                my $filename_NU = "$LOC/$id/EIJ/NU/antisense/$id.filtered_nu_intronmappers.$tmpname.sam";
                my $outfile_NU = $filename_NU;
                $outfile_NU =~ s/.sam$/.highexp.sam/i;
                if (-e "$outfile_NU"){
                    `rm $outfile_NU`;
                }
                my $shfile = "$shdir/run_shuf_nu_highexp.antisense.$id.$tmpname.sh";
                my $logname = "$logdir/run_shuf_highexp_nu.antisense.$id.$tmpname";
                if (($total_lc ne '0') && ($MIN_NU ne '0')){
                    open(OUTU, ">$shfile");
                    print OUTU "perl $path/run_shuf.pl $filename_NU $total_lc $MIN_NU > $outfile_NU\n";
                    print OUTU "echo \"got here\"\n";
                    close(OUTU);
                    while(qx{$status | wc -l} > $njobs){
                        sleep(10);
                    }
                    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
                    sleep(2);
                }
            }
	}
    }
}
close(INFILE);
print "got here\n";
