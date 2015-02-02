#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl get_novel_exons.pl <sample dirs> <loc> <gene info file> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<gene info file> a gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name

";

if(@ARGV<3){
    die $USAGE;
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];

my $master_list = "$LOC/master_list_of_exons.txt";
my $final_list = "$LOC/master_list_of_exons.$study.txt";
my $genes_file = $ARGV[2];
my %EX_START;
my %EX_END;
my %EXON_LIST;
my %STR;

open(SAM, $ARGV[0]) or die "cannot find file '$ARGV[0]'";
while(my $line = <SAM>){
    chomp($line);
    my $inf_file = "$LOC/$line/$line.list_of_inferred_exons.txt";
    open(IN, "<$inf_file") or die "cannot find file '$inf_file'\n";
    my @exons = <IN>;
    close(IN);
    foreach my $exon (@exons){
	chomp($exon);
	my @a = split(/\t/, $exon);
	my $exon_id = $a[0];
	my $str = $a[1];
	$EXON_LIST{$exon_id} = 1;
	$STR{$exon_id} = $str;
	(my $chr, my $exonstart, my $exonend) = $exon_id =~  /^(.*):(\d*)-(\d*)$/g;
	my $chr_st = "$chr.$exonstart";
	my $chr_end = "$chr.$exonend";
	push (@{$EX_START{$chr_st}}, $exonend);
	push (@{$EX_END{$chr_end}}, $exonstart);
    }
}
close(SAM);

open(IN, "<$master_list") or die "cannot find the 'master_list_of_exons.txt' file\n";
my @exons = <IN>;
close(IN);
foreach my $exon (@exons){
    chomp($exon);
    my @a = split(/\t/, $exon);
    my $exon_name = $a[0];
    my $strand = "";
    if (@a > 1){
        $strand = $a[1];
        $STR{$exon_name} = $strand;
    }
    $EXON_LIST{$exon_name} = 2;
    (my $chr, my $exonstart, my $exonend) = $exon_name =~  /^(.*):(\d*)-(\d*)/g;
    my $chr_st = "$chr.$exonstart";
    my $chr_end = "$chr.$exonend";
    push (@{$EX_START{$chr_st} }, $exonend);
    push (@{$EX_END{$chr_end} }, $exonstart);
}

my %gene_start;
my %gene_end;

open(GENE, $genes_file) or die "cannot find file \"$genes_file\"\n";
my $header = <GENE>;
chomp($header);
my @GHEADER = split(/\t/, $header);
my ($txchrcol, $exonStcol, $exonEndcol);
for(my $i=0; $i<@GHEADER; $i++){
    if ($GHEADER[$i] =~ /.chrom/){
        $txchrcol = $i;
    }
    if ($GHEADER[$i] =~ /.exonStarts$/){
        $exonStcol = $i;
    }
    if ($GHEADER[$i] =~ /.exonEnds$/){
        $exonEndcol = $i;
    }
}

if ( !defined($txchrcol) || !defined($exonStcol) || !defined($exonEndcol)){
    die "Your header must contain columns with the following suffixes: chrom, exonStarts, and exonEnds\n";
}
while(my $line = <GENE>){
    chomp($line);
    # skip header line
    if ($line =~ /^#/ || $line =~ /^chrom/){
        next;
    }
    my @a = split(/\t/, $line);
    my $gene_chr = $a[$txchrcol];
    my $exon_starts = $a[$exonStcol];
    my $exon_ends = $a[$exonEndcol];
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
        (my $chr, my $exonstart, my $exonend) = $key =~  /^(.*):(\d*)-(\d*)/g;
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
    (my $chr, my $start, my $end) = $exon =~ /^(.*):(\d*)-(\d*)/g;
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
    if (defined $STR{$exon}){
        print OUT "$exon\t$STR{$exon}\n";
        print NOV "$exon\t$STR{$exon}\n" if ($EXON_LIST{$exon} eq "1");
    }
    else{
        print OUT "$exon\n";
	print NOV "$exon\n" if ($EXON_LIST{$exon} eq "1");
    }
}
close(OUT);
close(NOV);
print "got here\n";



