#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Math::Matrix;

my $USAGE =  "\nUsage: perl runall_shuf_gnorm_highexp.pl <sample_dirs> <loc> [options]

where
<sample_dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs

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
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
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
$path =~ s/\/runall_shuf_gnorm_highexp.pl//; 

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

my ($MIN_U, $MIN_NU, $MIN_U_A, $MIN_NU_A);

my %HIGH_GENE;
my %HIGH_GENE_A;
open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $dir = $line;
    my $file = "$LOC/$dir/$id.high_expressers_gene.txt";
    if ($stranded eq "true"){
        $file = "$LOC/$dir/$id.high_expressers_gene.sense.txt";
    }
    open(IN, "$file") or die "cannot find file '$file'\n";
    my $header = <IN>;
    while (my $line2 = <IN>){
        chomp($line2);
        my @a = split(/\t/, $line2);
        my $geneid = $a[0];
        $HIGH_GENE{$geneid} = 1;
    }
    close(IN);
    if ($stranded eq "true"){
        my $file_a = "$LOC/$dir/$id.high_expressers_gene.antisense.txt";
        open(IN, "$file_a") or die "cannot find file '$file_a'\n";
        my $header = <IN>;
        while (my $line2 = <IN>){
            chomp($line2);
            my @a = split(/\t/, $line2);
            my $geneid = $a[0];
            $HIGH_GENE_A{$geneid} = 1;
        }
        close(IN);
    }
}
close(INFILE);

my $LINECOUNTS_U = 1000000000000000000000000;
my $LINECOUNTS_NU = 1000000000000000000000000;
my $LINECOUNTS_U_A = 1000000000000000000000000;
my $LINECOUNTS_NU_A = 1000000000000000000000000;

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
	    if ($N < $LINECOUNTS_U){
                $LINECOUNTS_U = $N;
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
            if ($N < $LINECOUNTS_U){
                $LINECOUNTS_U = $N;
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
            if ($N < $LINECOUNTS_U_A){
                $LINECOUNTS_U_A = $N;
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
            if ($N < $LINECOUNTS_NU){
                $LINECOUNTS_NU = $N;
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
            if ($N < $LINECOUNTS_NU){
                $LINECOUNTS_NU = $N;
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
            if ($N < $LINECOUNTS_NU_A){
                $LINECOUNTS_NU_A = $N;
            }
	}
    }
    close(IN);
}
=comment
print "MINU:$LINECOUNTS_U\n";
print "MINUA:$LINECOUNTS_U_A\n";
print "MINNU:$LINECOUNTS_NU\n";
print "MINNUA:$LINECOUNTS_NU_A\n";
=cut
my $jobname = "$study.shuf_gnorm_highexp";
my (@target, @target_a);
my (%INDEX, %INDEX_A);
my (@A, @A_A);
my $num_he = keys %HIGH_GENE;
my $num_he_a = keys %HIGH_GENE_A;
if (($num_he eq 0) && ($num_he_a eq 0)){
    my $lntemp = "$logdir/run_shuf_gnorm_u_highexp.temp";
    my $lntemp_nu = "$logdir/run_shuf_gnorm_nu_highexp.temp";
    `touch $lntemp.err $lntemp_nu.err`;
    `echo "got here" > $lntemp.out`;
    `echo "got here" > $lntemp_nu.out`;
}
#print "hecnt_sense:$num_he\n";
#print "hecnt_anti:$num_he_a\n";
##matrix
open(INFILE, $ARGV[0]);
while(my $id = <INFILE>) {
    chomp($id);
    my $gp_u = "$LOC/$id/$id.genepercents.txt";
    my $gp_nu = "$LOC/$id/$id.genepercents.nu.txt";
    my $cntinfo;
    if ($U eq "true"){
	if ($stranded eq "false"){
	    unless ($num_he eq 0){
		my $i = 0;
		foreach my $gene (keys %HIGH_GENE){
		    $INDEX{$i} = $gene;
		    my $line = `grep -w $gene $gp_u`;
		    my @x = split(/\t/, $line);
		    my $N = $x[1];
		    chomp($N);	      
		    my $p = ($N * 100) / 10000;
		    my $MIN_U = int(($LINECOUNTS_U * $N) / 100);
		    $target[$i] = $MIN_U;
		    for (my $ii = 0; $ii<$num_he;$ii++){
			if ($i eq $ii){
			    my $val = 1-$p;
			    $A[$i][$ii] = $val;
			}
			else{
			    my $val = -$p;
			    $A[$i][$ii] = $val;
			}
		    }
		    $i++;
		}
		my $pN = new Math::Matrix(\@target);
		my $pHE = new Math::Matrix(@A);
		my $Matrix = $pHE->concat($pN->transpose);
		my $M = $Matrix->solve;
=fordb
    print "\n========$id======\n";
		$pN -> print("pN:\n");
		print "-------\n";
		$pHE -> print("pHE:\n");
		print "-------\n";
		$Matrix -> print("Matrix:\n");
		print "-------\n";
		print "M:\n$M\n";
=cut
		my @m = split(/\n/,$M);
		for(my $i=0;$i<@m;$i++){
		    my $total_lc = 0;
		    my $toshuf = int($m[$i]);
		    my $gene = $INDEX{$i};
		    #print "gene\ttoshuf:$gene\t$toshuf\n";
		    if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.linecount.txt"){
			$cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.$gene.linecount.txt`;
		    }
		    my @c = split(/\t/, $cntinfo);
		    my $N = $c[1];
		    chomp($N);
		    $total_lc = $N;
		    my $filename_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.sam.gz";
		    my $outfile_U = $filename_U;
		    $outfile_U =~ s/.sam.gz$/.norm.sam.gz/i;
		    if (-e "$outfile_U"){
			`rm $outfile_U`;
		    }
		    my $shfile = "$shdir/run_shuf_gnorm_u_highexp.$id.$gene.sh";
		    my $logname = "$logdir/run_shuf_gnorm_u_highexp.$id.$gene";
		    if (($total_lc ne '0') && ($toshuf ne '0')){
			if ($toshuf> $total_lc){
			    die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			}
			open(OUTU, ">$shfile");
			if ($se eq "false"){
			    print OUTU "perl $path/run_shuf_gnorm.pl $filename_U $total_lc $toshuf $outfile_U\n";
			}
			if ($se eq "true"){
			    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $toshuf $outfile_U\n";
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
	    }
	}
	if ($stranded eq "true"){
	    unless ($num_he eq 0){
		#sense
		$gp_u = "$LOC/$id/$id.genepercents.sense.txt";
		my $i = 0;
		foreach my $gene (keys %HIGH_GENE){
		    $INDEX{$i} = $gene;
		    my $line = `grep -w $gene $gp_u`;
		    my @x = split(/\t/, $line);
		    my $N = $x[1];
		    chomp($N);
		    my $p = ($N * 100)/10000;
		    my $MIN_U = int(($LINECOUNTS_U * $N) / 100);
		    $target[$i] = $MIN_U;
		    for (my $ii = 0; $ii<$num_he;$ii++){
			if ($i eq $ii){
			    my $val = 1-$p;
			    $A[$i][$ii] = $val;
			}
			else{
			    my $val = -$p;
			    $A[$i][$ii] = $val;
			}
		    }
		    $i++;
		}
		my $pN = new Math::Matrix(\@target);
		my $pHE = new Math::Matrix(@A);
		my $Matrix = $pHE->concat($pN->transpose);
		my $M = $Matrix->solve;
		my @m = split(/\n/,$M);
=fordb
    print "\n========$id======\n";
            $pN -> print("pN:\n");
            print "-------\n";
            $pHE -> print("pHE:\n");
            print "-------\n";
            $Matrix -> print("Matrix:\n");
            print "-------\n";
            print "M:\n$M\n";
=cut
		for(my $i=0;$i<@m;$i++){
		    my $total_lc = 0;
		    my $toshuf = int($m[$i]);
		    my $gene = $INDEX{$i};
		    #print "gene\ttoshuf:$gene\t$toshuf\n";
		    if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.sense.linecount.txt"){
			$cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.$gene.sense.linecount.txt`;
		    }
		    my @c = split(/\t/, $cntinfo);
		    my $N = $c[1];
		    chomp($N);
		    $total_lc = $N;
		    my $filename_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.sense.sam.gz";
		    my $outfile_U = $filename_U;
		    $outfile_U =~ s/.sam.gz$/.norm.sam.gz/i;
		    if (-e "$outfile_U"){
			`rm $outfile_U`;
		    }
		    my $shfile = "$shdir/run_shuf_gnorm_u_highexp.$id.$gene.sense.sh";
		    my $logname = "$logdir/run_shuf_gnorm_u_highexp.sense.$id.$gene";
		    if (($total_lc ne '0') && ($toshuf ne '0')){
			if ($toshuf> $total_lc){
			    die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			}
			open(OUTU, ">$shfile");
			if ($se eq "false"){
			    print OUTU "perl $path/run_shuf_gnorm.pl $filename_U $total_lc $toshuf $outfile_U\n";
			}
			if ($se eq "true"){
			    print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $toshuf $outfile_U\n";
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
		unless ($num_he_a eq 0){
		    #antisense
		    $gp_u = "$LOC/$id/$id.genepercents.antisense.txt";
		    my $j = 0;
		    foreach my $gene (keys %HIGH_GENE_A){
			$INDEX_A{$j} = $gene;
			my $line = `grep -w $gene $gp_u`;
			my @x = split(/\t/, $line);
			my $N = $x[1];
			chomp($N);
			my $p = ($N * 100)/10000;
			my $MIN_U_A = int(($LINECOUNTS_U_A * $N) / 100);
			$target_a[$j] = $MIN_U_A;
			for (my $ii = 0; $ii<$num_he_a;$ii++){
			    if ($j eq $ii){
				my $val = 1-$p;
				$A_A[$j][$ii] = $val;
			    }
			    else{
				my $val = -$p;
				$A_A[$j][$ii] = $val;
			    }
			}
			$j++;
		    }
		    
		    my $pN_A = new Math::Matrix(\@target_a);
		    my $pHE_A = new Math::Matrix(@A_A);
		    my $Matrix_A = $pHE_A->concat($pN_A->transpose);
		    my $M_A = $Matrix_A->solve;
		    my @m_A = split(/\n/,$M_A);
=fordb
    print "\n========ANTI $id======\n";
            $pN_A -> print("pN:\n");
            print "-------\n";
            $pHE_A -> print("pHE:\n");
            print "-------\n";
            $Matrix_A -> print("Matrix:\n");
            print "-------\n";
            print "M:\n$M_A\n";
=cut
		    for(my $i=0;$i<@m_A;$i++){
			my $total_lc = 0;
			my $toshuf = int($m_A[$i]);
			my $gene = $INDEX_A{$i};
			#print "gene\ttoshuf:$gene\t$toshuf\n";
			if (-e "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.antisense.linecount.txt"){
			    $cntinfo = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.$gene.antisense.linecount.txt`;
			}
			my @c = split(/\t/, $cntinfo);
			my $N = $c[1];
			chomp($N);
			$total_lc = $N;
			my $filename_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.$gene.antisense.sam.gz";
			my $outfile_U = $filename_U;
			$outfile_U =~ s/.sam.gz$/.norm.sam.gz/i;
			if (-e "$outfile_U"){
			    `rm $outfile_U`;
			}
			my $shfile = "$shdir/run_shuf_gnorm_u_highexp.$id.$gene.antisense.sh";
			my $logname = "$logdir/run_shuf_gnorm_u_highexp.antisense.$id.$gene";
			if (($total_lc ne '0') && ($toshuf ne '0')){
			    if ($toshuf> $total_lc){
				die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			    }
			    open(OUTU, ">$shfile");
			    if ($se eq "false"){
				print OUTU "perl $path/run_shuf_gnorm.pl $filename_U $total_lc $toshuf $outfile_U\n";
			    }
			    if ($se eq "true"){
				print OUTU "perl $path/run_shuf.pl $filename_U $total_lc $toshuf $outfile_U\n";
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
		}
	    }
	}
    }
    if ($NU eq "true"){
	unless ($num_he eq 0){
	    if ($stranded eq "false"){
		my $i = 0;
		foreach my $gene (keys %HIGH_GENE){
		    $INDEX{$i} = $gene;
		    my $line = `grep -w $gene $gp_nu`;
		    my @x = split(/\t/, $line);
		    my $N = $x[1];
		    chomp($N);
		    my $p = ($N * 100) / 10000;
		    my $MIN_NU = int(($LINECOUNTS_NU * $N) / 100);
		    $target[$i] = $MIN_NU;
		    for (my $ii = 0; $ii<$num_he;$ii++){
			if ($i eq $ii){
			    my $val = 1-$p;
			    $A[$i][$ii] = $val;
			}
			else{
			    my $val = -$p;
			    $A[$i][$ii] = $val;
			}
		    }
		    $i++;
		}
		my $pN = new Math::Matrix(\@target);
		my $pHE = new Math::Matrix(@A);
		my $Matrix = $pHE->concat($pN->transpose);
		my $M = $Matrix->solve;
=fordb
    print "\n========$id======\n";
            $pN -> print("pN:\n");
            print "-------\n";
            $pHE -> print("pHE:\n");
            print "-------\n";
            $Matrix -> print("Matrix:\n");
            print "-------\n";
            print "M:\n$M\n";
=cut
		my @m = split(/\n/,$M);
		for(my $i=0;$i<@m;$i++){
		    my $total_lc = 0;
		    my $toshuf = int($m[$i]);
		    my $gene = $INDEX{$i};
		    #print "gene\ttoshuf:$gene\t$toshuf\n";
		    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.linecount.txt"){
			$cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.$gene.linecount.txt`;
		    }
		    my @c = split(/\t/, $cntinfo);
		    my $N = $c[1];
		    chomp($N);
		    $total_lc = $N;
		    my $filename_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.sam.gz";
		    my $outfile_NU = $filename_NU;
		    $outfile_NU =~ s/.sam.gz$/.norm.sam.gz/i;
		    if (-e "$outfile_NU"){
			`rm $outfile_NU`;
		    }
		    my $shfile = "$shdir/run_shuf_gnorm_nu_highexp.$id.$gene.sh";
		    my $logname = "$logdir/run_shuf_gnorm_nu_highexp.$id.$gene";
		    if (($total_lc ne '0') && ($toshuf ne '0')){
			if ($toshuf> $total_lc){
			    die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			}
			open(OUTNU, ">$shfile");
			if ($se eq "false"){
			    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
			}
			if ($se eq "true"){
			    print OUTNU "perl $path/run_shuf.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
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
	    }
	}
	if ($stranded eq "true"){
	    unless ($num_he eq 0){
		#sense
		$gp_nu = "$LOC/$id/$id.genepercents.nu.sense.txt";
		my $i = 0;
		foreach my $gene (keys %HIGH_GENE){
		    $INDEX{$gene} = $i;
		    my $line = `grep -w $gene $gp_nu`;
		    my @x = split(/\t/, $line);
		    my $N = $x[1];
		    chomp($N);
		    my $p = ($N * 100)/10000;
		    my $MIN_NU = int(($LINECOUNTS_NU * $N) / 100);
		    $target[$i] = $MIN_NU;
		    for (my $ii = 0; $ii<$num_he;$ii++){
			if ($i eq $ii){
			    my $val = 1-$p;
			    $A[$i][$ii] = $val;
			}
			else{
			    my $val = -$p;
                        $A[$i][$ii] = $val;
			}
		    }
		$i++;
		}
		my $pN = new Math::Matrix(\@target);
		my $pHE = new Math::Matrix(@A);
		my $Matrix = $pHE->concat($pN->transpose);
		my $M = $Matrix->solve;
		my @m = split(/\n/,$M);
=fordb
    print "\n========$id======\n";
            $pN -> print("pN:\n");
            print "-------\n";
            $pHE -> print("pHE:\n");
            print "-------\n";
            $Matrix -> print("Matrix:\n");
            print "-------\n";
            print "M:\n$M\n";
=cut
		for(my $i=0;$i<@m;$i++){
		    my $total_lc = 0;
		    my $toshuf = int($m[$i]);
		    my $gene = $INDEX{$i};
		    #print "gene\ttoshuf:$gene\t$toshuf\n";
		    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.sense.linecount.txt"){
			$cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.$gene.sense.linecount.txt`;
		    }
		    my @c = split(/\t/, $cntinfo);
		    my $N = $c[1];
		    chomp($N);
		    $total_lc = $N;
		    my $filename_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.sense.sam.gz";
		    my $outfile_NU = $filename_NU;
		    $outfile_NU =~ s/.sam.gz$/.norm.sam.gz/i;
		    if (-e "$outfile_NU"){
			`rm $outfile_NU`;
		    }
		    my $shfile = "$shdir/run_shuf_gnorm_nu_highexp.$id.$gene.sense.sh";
		    my $logname = "$logdir/run_shuf_gnorm_nu_highexp.sense.$id.$gene";
		    if (($total_lc ne '0') && ($toshuf ne '0')){
			if ($toshuf> $total_lc){
			    die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			}
			open(OUTNU, ">$shfile");
			if ($se eq "false"){
			    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
			}
			if ($se eq "true"){
			    print OUTNU "perl $path/run_shuf.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
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
	    }
	    unless ($num_he_a eq 0){
            #antisense
		$gp_nu = "$LOC/$id/$id.genepercents.nu.antisense.txt";
		my $j = 0;
		foreach my $gene (keys %HIGH_GENE_A){
		    $INDEX_A{$j} = $gene;
		    my $line = `grep -w $gene $gp_nu`;
		    my @x = split(/\t/, $line);
		    my $N = $x[1];
		    chomp($N);
		    my $p = ($N * 100)/10000;
		    my $MIN_NU_A = int(($LINECOUNTS_NU_A * $N) / 100);
		    $target_a[$j] = $MIN_NU_A;
		    for (my $ii = 0; $ii<$num_he_a;$ii++){
			if ($j eq $ii){
			    my $val = 1-$p;
			    $A_A[$j][$ii] = $val;
			}
			else{
			    my $val = -$p;
			    $A_A[$j][$ii] = $val;
			}
		    }
		    $j++;
		}
		
		my $pN_A = new Math::Matrix(\@target_a);
		my $pHE_A = new Math::Matrix(@A_A);
		my $Matrix_A = $pHE_A->concat($pN_A->transpose);
		my $M_A = $Matrix_A->solve;
		my @m_A = split(/\n/,$M_A);
=fordb
    print "\n========ANTI $id======\n";
            $pN_A -> print("pN:\n");
            print "-------\n";
            $pHE_A -> print("pHE:\n");
            print "-------\n";
            $Matrix_A -> print("Matrix:\n");
            print "-------\n";
            print "M:\n$M_A\n";
=cut
		for(my $i=0;$i<@m_A;$i++){
		    my $total_lc = 0;
		    my $toshuf = int($m_A[$i]);
		    my $gene = $INDEX_A{$i};
		    #print "gene\ttoshuf:$gene\t$toshuf\n";
		    if (-e "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.antisense.linecount.txt"){
			$cntinfo = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.$gene.antisense.linecount.txt`;
		    }
		    my @c = split(/\t/, $cntinfo);
		    my $N = $c[1];
		    chomp($N);
		    $total_lc = $N;
		    my $filename_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.$gene.antisense.sam.gz";
		    my $outfile_NU = $filename_NU;
		    $outfile_NU =~ s/.sam.gz$/.norm.sam.gz/i;
		    if (-e "$outfile_NU"){
			`rm $outfile_NU`;
		    }
		    my $shfile = "$shdir/run_shuf_gnorm_nu_highexp.$id.$gene.antisense.sh";
		    my $logname = "$logdir/run_shuf_gnorm_nu_highexp.antisense.$id.$gene";
		    if (($total_lc ne '0') && ($toshuf ne '0')){
			if ($toshuf > $total_lc){
			    die "ERROR: something is wrong with the input files. $toshuf cannot be greater than $total_lc\n\n";
			}
			open(OUTNU, ">$shfile");
			if ($se eq "false"){
			    print OUTNU "perl $path/run_shuf_gnorm.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
			}
			if ($se eq "true"){
			    print OUTNU "perl $path/run_shuf.pl $filename_NU $total_lc $toshuf $outfile_NU\n";
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
	    }
	}
    }
}

print "got here\n";
