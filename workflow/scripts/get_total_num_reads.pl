#!/usr/bin/env perl
use strict;
use warnings;
use lib ("$Bin/pm/lib/perl5");
my $USAGE = "\nUsage: perl get_total_num_reads.pl <in file> <out file>";
if(@ARGV<2) {
    die $USAGE;
}


open(INFILE, $input_files) or die "cannot find file '$input_files'\n";
my $i = 0;
while(my $line = <INFILE>){
    chomp($line);
    unless (-e $line){
	die "ERROR: cannot find \"$line\"\n";
    }
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x;
    if ($gz eq "true"){
	$x= "echo \"zcat $line | wc -l | xargs echo -n >> $temp_file.$i.$study && echo ' $line' >> $temp_file.$i.$study\" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out";
    }
    else {
	$x ="echo \"wc -l < $line | xargs echo -n >> $temp_file.$i.$study && echo ' $line' >> $temp_file.$i.$study\" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out";
    }
    if ($hn_only eq "true"){
	$ssh->system($x) or
	    die "remote command failed: " . $ssh->error;
    }
    else{
	`$x`;
    }
    sleep(2);
    $i++;
}
close(INFILE);

my $outfile_final = "$stats_dir/total_num_reads.txt";
while (qx{$status | grep -c $jobname} > 0){
    sleep(10);
}
my @g = glob("$logname.*.err");
if (@g > 0){
    if (qx{cat $logname.*.err | wc -l} > 0){
	die "ERROR: wc -l step had errors\n";
    }
}
else{
    die "ERROR: wc -l step did not run\n";
}
my @g2 = glob("$temp_file.*.$study");
if (@g2 eq 0){
    die "ERROR: wc -l step did not run\n";
}
open(DIRS, $sample_dirs) or die "cannot find file '$sample_dirs'\n";
open(OUTFINAL, ">$outfile_final");
while(my $dir = <DIRS>){
    chomp($dir);
    my $num;
    my $id = $dir;
    my $total_num_reads = `grep -w $id $temp_file.*.$study`;
    my @fields = split(" ", $total_num_reads);
    my @t = glob ("$temp_file*$study");
    if (@t > 1){
	my $first = $fields[0];
	my @a = split(":", $first);
	$num = $a[1];
    }
    else{
	$num = $fields[0];
    }
    if ($fq eq "true"){
	$num = $num/4;
    }
    if ($fa eq "true"){
	$num = $num/2;
    }    
    print OUTFINAL "$id\t$num\n";
}
close(DIRS);
close(OUTFINAL);

print "got here\n";
`rm $temp_file*$study`;
