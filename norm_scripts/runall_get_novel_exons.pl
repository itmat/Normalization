#!/usr/bin/env perl
use strict;
use warnings;
if(@ARGV<4){
    my $USAGE = "\nUsage: perl runall_get_novel_exons.pl <sample dirs> <loc> <sam file name> <gene info file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<gene info file> a gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name

options: 
-min <n> : min is set at 10 by default

-max <n> : max is set at 1200 by default

";
    die $USAGE;
}

my $min = 10;
my $max = 1200;

for(my $i=4; $i<@ARGV; $i++) {
    my $argument_recognized = 0;
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_get_novel_exons.pl//;

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];

my $sam_name = $ARGV[2];
my $junc_name = $sam_name;
$junc_name =~ s/.sam/_junctions_all.rum/;
my $sorted_junc = $junc_name;
$sorted_junc =~ s/.rum/.sorted.rum/;
my $master_list = "$LOC/master_list_of_exons.txt";
my $final_list = "$LOC/master_list_of_exons.$study.txt";
my $annot_file = $ARGV[3];
my %EX_START;
my %EX_END;
my %EXON_LIST;

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $outfile = "$id.list_of_inferred_exons.txt";
    `perl $path/rum-2.0.5_05/bin/sort_by_location.pl --skip 1 -o $LOC/$dir/$sorted_junc --location 1 $LOC/$dir/$junc_name`;
    `perl $path/get_novel_exons.pl $LOC/$dir/$sorted_junc $LOC/$dir/$outfile -min $min -max $max`;
    open(IN, "<$LOC/$dir/$outfile") or die "cannot find file '$LOC/$dir/$outfile'\n";
    my @exons = <IN>;
    close(IN);
    foreach my $exon (@exons){
	chomp($exon);
	$EXON_LIST{$exon} = 1;
	(my $chr, my $exonstart, my $exonend) = $exon =~  /^(.*):(\d*)-(\d*)$/g;
	push (@{$EX_START{"$chr.$exonstart"}}, $exonend);
	push (@{$EX_END{"$chr.$exonend"}}, $exonstart);
    }
}
close(INFILE);

open(IN, "<$master_list") or die "cannot find the 'master_list_of_exons.txt' file\n";
my @exons = <IN>;
close(IN);
foreach my $exon (@exons){
    chomp($exon);
    $EXON_LIST{$exon} = 2;
    (my $chr, my $exonstart, my $exonend) = $exon =~  /^(.*):(\d*)-(\d*)$/g;
    push (@{$EX_START{"$chr.$exonstart"} }, $exonend);
    push (@{$EX_END{"$chr.$exonend"} }, $exonstart);
}

my %gene_start;
my %gene_end;

open(GENE, $annot_file) or die "cannot find the '$annot_file' file\n";
while(my $line = <GENE>){
    chomp($line);
    # skip header line
    if ($line =~ /^#/ || $line =~ /^chrom/){
	next;
    }
    my @a = split(/\t/, $line);
    my $gene_chr = $a[0];
    my $exon_starts = $a[5];
    my $exon_ends = $a[6];
    my @s = split(",", $exon_starts);
    my $last_exon_start = $s[@s-1] + 1;
    $gene_start{"$gene_chr.$last_exon_start"} = 1;
    my @e = split(",", $exon_ends);
    my $first_exon_end =$e[0];
    $gene_end{"$gene_chr.$first_exon_end"} = 1;
}
close(GENE);

foreach my $key (keys %EXON_LIST){
    if ($EXON_LIST{$key} eq "1"){
	(my $chr, my $exonstart, my $exonend) = $key =~  /^(.*):(\d*)-(\d*)$/g;
	my $start = "$chr.$exonstart";
	my $end = "$chr.$exonend";
	if ((exists $gene_start{$start}) && (exists $gene_end{$end})){
	    delete $EXON_LIST{$key};
	}
	elsif ((exists $EX_START{$start}) && (exists $EX_END{$end})){
	    my @sorted_exonend = sort {$a <=> $b} @{$EX_START{$start}};
	    my @sorted_exonstart = sort {$a <=> $b} @{$EX_END{$end}};
	    my $min_end = $sorted_exonend[0];
	    my $max_start = $sorted_exonstart[@sorted_exonstart-1];
	    if ($min_end < $max_start){
		delete $EXON_LIST{$key};
	    }
	}
    }
}

%EX_START = ();
%EX_END = ();

# put all exon starts and exon ends into hash (annotated and novel)
foreach my $exon (keys %EXON_LIST){
    (my $chr, my $start, my $end) = $exon =~ /^(.*):(\d*)-(\d*)$/g;
    push (@{$EX_START{"$chr.$start"}}, $exon);
    push (@{$EX_END{"$chr.$end"}}, $exon);
}

# loop through novel exons and delete from hash if it connects two shorter exons that don't overlap
foreach my $exon (keys %EXON_LIST){
    if ($EXON_LIST{$exon} eq "1"){
	(my $chr, my $start, my $end) = $exon =~ /^(.*):(\d*)-(\d*)$/g;
	my $CHECK_START = "$chr.$start";
	my $size_start = @{$EX_START{$CHECK_START}};
	my $CHECK_END = "$chr.$end";
	my $size_end = @{$EX_END{$CHECK_END}};
	if (($size_start > 1) && ($size_end > 1)){
	    for (my $i=0;$i<$size_start;$i++){
		unless ($exon eq $EX_START{$CHECK_START}[$i]){
		    my $exon1 = $EX_START{$CHECK_START}[$i];
		    (my $exon1_chr, my $exon1_st, my $exon1_end) = $exon1 =~ /^(.*):(\d*)-(\d*)$/g;
		    for (my $j=0;$j<$size_end;$j++){
			unless ($exon eq $EX_END{$CHECK_END}[$j]){
			    my $exon2 = $EX_END{$CHECK_END}[$j];
			    (my $exon2_chr, my $exon2_st, my $exon2_end) = $exon2 =~ /^(.*):(\d*)-(\d*)$/g;
			    my $diff = $exon1_end - $exon2_st;
			    if ($diff <= 0){
				delete $EXON_LIST{$exon};
			    }
			}
		    }
		}
	    }
	}
    }
}


open(OUT, ">$final_list");
open(NOV, ">$LOC/$study.list_of_novel_exons.txt");
foreach my $exon (keys %EXON_LIST){
    print OUT "$exon\n";
    print NOV "$exon\n" if ($EXON_LIST{$exon} eq "1");
}
close(OUT);
close(NOV);
print "got here\n";
