#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<4) {
    die "usage: perl runblast.pl <dir> <loc> <blastdir> <query> [option]

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


";
}
my $type = "";
my $type_arg = 0;
my $gz = "false";
my $pe = "false";
my $se = "false";
my $sepe = 0;
my $fwd = "";
my $rev = "";
for(my $i=4;$i<@ARGV;$i++){
    my $option_found = "false";
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


my $dir = $ARGV[0];
my $LOC = $ARGV[1];
my $blastdir = $ARGV[2];
my $query = $ARGV[3];

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runblast.pl//;

my $idsfile = "$LOC/$dir/$dir.ribosomalids.txt";
if (-e $idsfile){
    `rm $idsfile`;
}
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
my $database1 = "db1.$dir";
my $database2 = "db2.$dir";
if ($se eq "true"){
    if ($gz eq "false"){
	my $x = `$blastdir/bin/makeblastdb -dbtype nucl -in $file1 -out $LOC/$dir/$database1`;
    }
    else{
	my $x = `gunzip -c $file1 | $blastdir/bin/makeblastdb -dbtype nucl -in - -out $LOC/$dir/$database1 -title $database1`;
    }
}
if ($pe eq "true"){
    if ($gz eq "false"){
        my $x = `$blastdir/bin/makeblastdb -dbtype nucl -in $file1 -out $LOC/$dir/$database1`;
        my $y = `$blastdir/bin/makeblastdb -dbtype nucl -in $file2 -out $LOC/$dir/$database2`;
    }
    else{
	my $x = `gunzip -c $file1 | $blastdir/bin/makeblastdb -dbtype nucl -in - -out $LOC/$dir/$database1 -title $database1`;
	my $y = `gunzip -c $file2 | $blastdir/bin/makeblastdb -dbtype nucl -in - -out $LOC/$dir/$database2 -title $database2`;
    }
}

#blastn
if ($se eq "true"){
    my $x = `$blastdir/bin/blastn -task blastn -db $LOC/$dir/$database1 -query $query -num_alignments 1000000000 > $file1.blastout`;
    my $p = `perl $path/parseblastout.pl $file1.blastout > $idsfile`;
}
if ($pe eq "true"){
    my $x = `$blastdir/bin/blastn -task blastn -db $LOC/$dir/$database1 -query $query -num_alignments 1000000000 > $file1.blastout`;
    my $y = `$blastdir/bin/blastn -task blastn -db $LOC/$dir/$database2 -query $query -num_alignments 1000000000 > $file2.blastout`;
    my $p = `perl $path/parseblastout.pl $file1.blastout > $idsfile.tmp1`;
    my $q = `perl $path/parseblastout.pl $file2.blastout > $idsfile.tmp2`;
    my $z = `cat $idsfile.tmp1 $idsfile.tmp2 | sort -u > $idsfile`;
}
if (-e "$idsfile.tmp1"){
    `rm $idsfile.tmp1`;
}
if (-e "$idsfile.tmp2"){ 
    `rm $idsfile.tmp2`;
}

print "got here\n";
