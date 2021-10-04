#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;
#use Net::SSH qw(ssh);

my $USAGE =  "usage: perl runblast.pl <dir> <loc> <blastdir> <query> [option]

where:
<dir> name of the sample directory
<loc> is the directory with the sample directories
<blast dir> is the blast dir (full path)
<query> query file (full path)

options:
 -gz: set this if the unaligned files are compressed
 -fa: set this if the unaligned files are in fasta format
 -fq: set this if the unaligned files are in fastq format
 -se \"<unaligned>\" : set this if the data are single end and provide a unaligned file
 -pe \"<unlaligned1>,<unaligned2>\" : set this if the data are paired end and provide two unaligned files 
 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. 6144, 6G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : help message

";
if(@ARGV<4) {
    die $USAGE;
}
my $type = "";
my $type_arg = 0;
my $gz = "false";
my $pe = "false";
my $se = "false";
my $sepe = 0;
my $fwd = "";
my $rev = "";

my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $njobs = 200;
my $status = "";
my $hn_only = "false";
my $hn_name = "";
my $ssh;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=4;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-headnode'){
	$option_found = "true";
	$hn_only = "true";
	$hn_name = $ARGV[$i+1];
	$i++;
	$ssh = Net::OpenSSH->new($hn_name,
				 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }
    if ($ARGV[$i] eq '-gz'){
	$option_found ="true";
	$gz = "true";
    }
    if ($ARGV[$i] eq '-fa'){
	$type = "-fa";
	$type_arg++;
	$option_found="true";
    }
    if ($ARGV[$i] eq '-fq'){
        $type ="-fq";
	$type_arg++;
	$option_found="true";
    }
    if ($ARGV[$i] eq '-se'){
	$option_found = "true";
	$se = "true";
	$sepe++;
	$fwd = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-pe'){
	$option_found ="true";
        $pe = "true";
	$sepe++;
	my $all = $ARGV[$i+1];
	my @a = split(",",$all);
	$fwd = $a[0];
	$rev = $a[1];
        $i++;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
	$mem = "6144";
        $status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
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
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq "" | $status eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option> ,<queue_name_for_6G>, <status>\".\n";
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
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if ($type_arg ne '1'){
    die "please specify the type of unaligned data : '-fa' or '-fq'\n";
}

if ($sepe ne '1'){
    die "please specify the type of data : '-se <unaligned> or '-pe \"<unaligned1>,<unaligned2>\"'\n";
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

my $dir = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $blastdir = $ARGV[2];
my $query = $ARGV[3];

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runblast.pl//;

my $file1 = $fwd;
my $file2 = $rev;

#convert fastq to fasta
if ($type eq "-fq"){
    $file1 .= ".fa";
    $file2 .= ".fa";
    if ($gz eq "true"){
	$file1 .= ".gz";
	$file2 .= ".gz";
    }
    if ($se eq "true"){
	if ($gz eq "false"){
	    my $x = `perl $path/fastq2fasta.pl $fwd $file1`;
	}
	else{
	    my $x = `perl $path/fastq2fasta.pl $fwd $file1 -gz`;
	}
    }
    if ($pe eq "true"){
	if ($gz eq "false"){
	    my $x = `perl $path/fastq2fasta.pl $fwd $file1`;
	    my $y = `perl $path/fastq2fasta.pl $rev $file2`;
	}
	else{
	    my $x = `perl $path/fastq2fasta.pl $fwd $file1 -gz`;
	    my $y =`perl $path/fastq2fasta.pl $rev $file2 -gz`;
	}
    }
}

#makeblastdb
my $database1 = "blastdb1.$dir";
my $database2 = "blastdb2.$dir";
my $max_db_file_size = "5GB";

if ($se eq "true"){
    if ($gz eq "false"){
	my $x = `$blastdir/bin/makeblastdb -dbtype nucl -in $file1 -max_file_sz $max_db_file_size -out $LOC/$dir/$database1`;
    }
    else{
	my $x = `gunzip -c $file1 | $blastdir/bin/makeblastdb -dbtype nucl -max_file_sz $max_db_file_size -in - -out $LOC/$dir/$database1 -title $database1`;
    }
}
if ($pe eq "true"){
    if ($gz eq "false"){
        my $x = `$blastdir/bin/makeblastdb -dbtype nucl -max_file_sz $max_db_file_size -in $file1 -out $LOC/$dir/$database1`;
        my $y = `$blastdir/bin/makeblastdb -dbtype nucl -max_file_sz $max_db_file_size -in $file2 -out $LOC/$dir/$database2`;
    }
    else{
	my $x = `gunzip -c $file1 | $blastdir/bin/makeblastdb -dbtype nucl -max_file_sz $max_db_file_size -in - -out $LOC/$dir/$database1 -title $database1`;
	my $y = `gunzip -c $file2 | $blastdir/bin/makeblastdb -dbtype nucl -max_file_sz $max_db_file_size -in - -out $LOC/$dir/$database2 -title $database2`;
    }
}

#blastn
my @g = glob("$LOC/$dir/$database1*nin");
my %DBS1;
foreach my $file (@g){
    my @s = split("/",$file);
    my $dbname = $s[@s-1];
    $dbname =~ s/.nin$//;
    my $blastout = "$LOC/$dir/$dbname.blastout";
    $DBS1{$dbname}= $blastout;
}
my @g2 = glob("$LOC/$dir/$database2*nin");
my %DBS2;
foreach my $file (@g2){
    my @s = split("/",$file);
    my $dbname = $s[@s-1];
    $dbname =~ s/.nin$//;
    my $blastout = "$LOC/$dir/$dbname.blastout";
    $DBS2{$dbname}= $blastout;
}
my $jobname = "$study.runblast";
open(QU, $query) or die "cannot find file '$query'\n";
my $tempq = "$LOC/$dir/query.temp";
my $seq = "";
my $name = "";
my $tcnt = 0;
while(my $line = <QU>){
    chomp($line);
    if ($line =~ /^\>/){
	unless ($seq =~ /^$/){
	    open(TQ, ">$tempq.$tcnt");
	    print TQ "$name\n$seq\n";
	    close(TQ);
	    foreach my $db1 (keys %DBS1){
		my $bout = "$DBS1{$db1}.$tcnt";
		my $logname = "$logdir/runblast.$db1.$tcnt";
		while (qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
#		my $x = `echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db1 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err`;
		my $x = "echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db1 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err";
		if ($hn_only eq "true"){
		    $ssh->system($x) or
			die "remote command failed: " . $ssh->error;
#		    ssh($hn_name,$x);
		}
		else{
		    `$x`;
		}
		sleep(2);
	    }
	    foreach my $db2 (keys %DBS2){
		my $bout = "$DBS2{$db2}.$tcnt";
		my $logname = "$logdir/runblast.$db2.$tcnt";
		while (qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
#		my $y = `echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db2 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err`;
		my $y = "echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db2 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err";
                if ($hn_only eq "true"){
		    $ssh->system($y) or
			die "remote command failed: " . $ssh->error;
                    #ssh($hn_name,$y);
                }
                else{
                    `$y`;
                }
		sleep(2);
	    }
	}
	$name = $line;
	$seq = "";
	$tcnt++;
    }
    else{
	$seq .= $line;
    }
}
#last query 
open(TQ, ">$tempq.$tcnt");
print TQ "$name\n$seq\n";
close(TQ);

foreach my $db1 (keys %DBS1){
    my $bout = "$DBS1{$db1}.$tcnt";
    my $logname = "$logdir/runblast.$db1.$tcnt";
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
#    my $x = `echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db1 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err`;
    my $x = "echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db1 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err";
    if ($hn_only eq "true"){
        $ssh->system($x) or
            die "remote command failed: " . $ssh->error;
	#ssh($hn_name,$x);
    }
    else{
	`$x`;
    }
    sleep(2);
}
foreach my $db2 (keys %DBS2){
    my $bout = "$DBS2{$db2}.$tcnt";
    my $logname = "$logdir/runblast.$db2.$tcnt";
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
#    my $y = `echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db2 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err`;
    my $y = "echo \"$blastdir/bin/blastn -task blastn -db $LOC/$dir/$db2 -query $tempq.$tcnt -num_descriptions 1000000000 -num_alignments 1000000000 > $bout && echo \"got here\"\" | $submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err";
    if ($hn_only eq "true"){
        $ssh->system($y) or
            die "remote command failed: " . $ssh->error;
	#ssh($hn_name,$y);
    }
    else{
	`$y`;
    }
    sleep(2);
}
if ($type eq "-fq"){
    if ($se eq "true"){
	`rm $file1`;
    }
    if ($pe eq "true"){
	`rm $file1 $file2`;
    }
}

print "got here\n";
