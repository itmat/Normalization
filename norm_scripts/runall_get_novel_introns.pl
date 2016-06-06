#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl runall_get_novel_introns.pl <sample dirs> <loc> <sam file name> <gene info file> 

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file
<gene info file> a gene annotation file including chrom, strand, txStrand, and txEnd

";
if(@ARGV<4){    
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_get_novel_introns.pl//;

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];

my $sam_name = $ARGV[2];
my $junc_name = $sam_name;
$junc_name =~ s/.sam$/_junctions_all.rum/i;
$junc_name =~ s/.bam$/_junctions_all.rum/i;
my $master_list = "$LOC/master_list_of_introns.txt";
my $final_list = "$LOC/master_list_of_introns.$study.txt";
my $genes_file = $ARGV[3];

open(INFO, $genes_file) or die "cannot find file \"$genes_file\"\n";
my $header = <INFO>;
chomp($header);
my @HEADER = split(/\t/, $header);
my ($txchrcol, $txstartcol, $txendcol);
for(my $i=0; $i<@HEADER; $i++){
    if ($HEADER[$i] =~ /chrom/){
        $txchrcol = $i;
    }
    if ($HEADER[$i] =~ /txStart/){
        $txstartcol = $i;
    }
    if ($HEADER[$i] =~ /txEnd/){
        $txendcol = $i;
    }
}

if (!defined($txchrcol) || !defined($txstartcol)|| !defined($txendcol)){
    die "Your header must contain columns with the following suffixes: chrom, txStart, and txEnd\n";
}
my $gchr = "";
my $gstart = "";
my $gend = "";
my %GLIST;

while(my $line = <INFO>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $txchr = $a[$txchrcol];
    my $txst = $a[$txstartcol];
    my $txend = $a[$txendcol];
    if ($gchr eq $txchr){
	if ($gend >= $txst){ #overlaps
	    my @st = ($gstart, $txst);
	    my @end = ($gend, $txend);
	    $gstart = &get_min(@st);
	    $gend = &get_max(@end);
	}
	else{ #does not overlap
	    $gstart++;
	    $gstart = $gstart - 5000; #flanking
	    if ($gstart < 0){
		$gstart = 1;
	    }
	    $gend = $gend + 5000; #flanking
	    my $gene = "$gchr:$gstart-$gend";
	    $GLIST{$gene} = 1;
	    $gstart = $txst;
	    $gend = $txend;
	}
    }
    else{
	$gchr = $txchr;
	$gstart = $txst;
	$gend = $txend;
    }
}
close(INFO);

my (%INTRON_LIST, %STR);
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $outfile = "$id.list_of_inferred_introns.txt";
    `perl $path/get_novel_introns.pl $LOC/$dir/$junc_name $LOC/$dir/$outfile`;
    open(IN, "<$LOC/$dir/$outfile") or die "cannot find file '$LOC/$dir/$outfile'\n";
    my @introns = <IN>;
    close(IN);
    foreach my $intron (@introns){
	chomp($intron);
	my @a = split(/\t/, $intron);
	my $intron_id = $a[0];
	my $str = $a[1];
	$INTRON_LIST{$intron_id} = 1;
	$STR{$intron_id} = $str;
    }
}
close(INFILE);
my %FEATURE;
open(IN, "<$master_list") or die "cannot find '$master_list'\n";
my @introns = <IN>;
close(IN);
foreach my $intron (@introns){
    chomp($intron);
    my @a = split(/\t/, $intron);
    my $intron_name = $a[0];
    my $strand = "";
    if (@a > 1){
	$strand = $a[1];
	$STR{$intron_name} = $strand;
    }
    $FEATURE{$intron_name} = 1;
    $INTRON_LIST{$intron_name} = 2;
}

my (%INT_START, %INT_END);
# put all intron starts and intron ends into hash (annotated and novel)
foreach my $intron (keys %INTRON_LIST){
    (my $chr, my $start, my $end) = $intron =~ /^(.*):(\d*)-(\d*)/g;
    push (@{$INT_START{"$chr.$start"}}, $intron);
    push (@{$INT_END{"$chr.$end"}}, $intron);
}

# loop through novel introns and delete from hash if it connects two shorter introns that don't overlap (remove introns that contain skipped exons)
foreach my $intron (keys %INTRON_LIST){
    if ($INTRON_LIST{$intron} eq "1"){
        (my $chr, my $start, my $end) = $intron =~ /^(.*):(\d*)-(\d*)$/g;
        my $CHECK_START = "$chr.$start";
        my $size_start = @{$INT_START{$CHECK_START}};
        my $CHECK_END = "$chr.$end";
	my $size_end = @{$INT_END{$CHECK_END}};
	if (($size_start > 1) && ($size_end > 1)){
            for (my $i=0;$i<$size_start;$i++){
                unless ($intron eq $INT_START{$CHECK_START}[$i]){
                    my $intron1 = $INT_START{$CHECK_START}[$i];
                    (my $intron1_chr, my $intron1_st, my $intron1_end) = $intron1 =~ /^(.*):(\d*)-(\d*)$/g;
                    for (my $j=0;$j<$size_end;$j++){
                        unless ($intron eq $INT_END{$CHECK_END}[$j]){
                            my $intron2 = $INT_END{$CHECK_END}[$j];
                            (my $intron2_chr, my $intron2_st, my $intron2_end) = $intron2 =~ /^(.*):(\d*)-(\d*)$/g;
			    if ((defined $intron2_chr) && (defined $intron1_chr)){
				my $diff = $intron1_end - $intron2_st;
				if ($diff <= 0){
				    delete $INTRON_LIST{$intron};
				}
			    }
                        }
                    }
                }
            }
	}
    }
}

foreach my $gene (keys %GLIST){
    (my $gchr, my $gstart, my $gend) = $gene =~ /^(.*):(\d*)-(\d*)$/g;
    foreach my $intron (keys %INTRON_LIST){
	if ($INTRON_LIST{$intron} eq "1"){
            (my $chr, my $start, my $end) = $intron =~ /^(.*):(\d*)-(\d*)$/g;
            if ($gchr eq $chr){
                if (($gstart <= $start) && ( $gend >= $end)){ #if novel intron is contained in annotated gene, delete
                    delete $INTRON_LIST{$intron};
                }
            }
            else{
                next;
            }
	}
    }
}

=comment
foreach my $intron (keys %INTRON_LIST){
    if ($INTRON_LIST{$intron} eq '1'){
        print "NOVEL2:$intron\n";
    }
}
=cut

open(OUT, ">$final_list");
open(NOV, ">$LOC/$study.list_of_novel_introns.txt");
foreach my $intron (keys %INTRON_LIST){
    if (defined $STR{$intron}){
	print OUT "$intron\t$STR{$intron}\n";
	print NOV "$intron\t$STR{$intron}\n" if ($INTRON_LIST{$intron} eq "1");
    }
    else{
	print OUT "$intron\n";
	print NOV "$intron\n" if ($INTRON_LIST{$intron} eq "1");
    }
}
close(OUT);
close(NOV);

print "got here\n";

sub get_min(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[0];
}

sub get_max(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[@sorted_array-1];
}
