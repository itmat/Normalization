#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl quantify_genes.pl <sam2genes output> <genes file> <output file> 

<sam2gene output> output file from sam2gene.pl script
<genes file> master_list_of_ensGeneIDs.txt file
<output file> name of output file

\n";

if (@ARGV<3){
    die $USAGE;
}

my $input = $ARGV[0];
my $genes = $ARGV[1];
my $outfile = $ARGV[2];

my (%GENE, %GENE_COORDS, %GENE_counts_min, %GENE_counts_max, %READ_NU);
open(IN, $genes);
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $gene_id = $a[0];
    my $gene_sym = $a[1];
    my $gene_coord = $a[2];
    $GENE{$gene_id} = $gene_sym;
    $GENE_counts_min{$gene_id} = 0;
    $GENE_counts_max{$gene_id} = 0;
    $GENE_COORDS{$gene_id} = $gene_coord;
}
close(IN);

open(INFILE2, $input);
$header = <INFILE2>;
while(my $line = <INFILE2>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $read_id = $a[0];
    my $gene_ids = $a[2];
    my $gene_syms = $a[3];
    my $gene_tag = $a[5];
    if ($gene_ids =~ /^$/){
	next;
    }
    my @b = split(",", $gene_ids);
    if (@b == 1){ #single gene id
	if ($gene_tag == 1){ #unique mapper
	    $GENE_counts_min{$gene_ids}++;
#	    print "$line\nUNIQUE\tONEGENE\tMIN\t$gene_ids\n";
	}
	else{ #non-unique mapper
	    my $check = 0;
	    #if gene id exists in the $READ{$read_id} array, do not increment counter 
	    if (exists $READ_NU{$read_id}){
		for (my $j=0; $j<@{$READ_NU{$read_id}}; $j++){
		    if ($READ_NU{$read_id}[$j] eq $gene_ids){
			$check = 1;
		    }
		}
	    }
	    if ($check == 0){
		$GENE_counts_max{$gene_ids}++;
		push (@{$READ_NU{$read_id}}, $gene_ids);
#		print "$line\nNU\tONEGENE\tMAX\t$gene_ids\n";
	    }
	}
    }
    else{ #multiple gene ids
	if ($gene_tag == 1){ #unique mapper
	    for(my $i=0;$i<@b;$i++){
		$GENE_counts_max{$b[$i]}++;
#		    print "$line\nUNIQUE\tMULTGENE\tMAX\t$b[$i]\n";
	    }
	}
	else{ #non-unique read
	    for(my $i=0;$i<@b;$i++){
		my $check =0;
                #if gene id exists in the $READ{$read_id} array, do not increment counter
		if (exists $READ_NU{$read_id}){
                    for (my $j=0; $j<@{$READ_NU{$read_id}}; $j++){
                        if ($READ_NU{$read_id}[$j] eq $b[$i]){
                           $check = 1;
                        }
                    }
		}
                if ($check == 0){
                    $GENE_counts_max{$b[$i]}++;
                    push (@{$READ_NU{$read_id}}, $b[$i]);
#		    print "$line\nNON-UNIQUE\tMULTGENE\tMAX\t$b[$i]\n";
		}
            }
	}
    }
}

open(OUT, ">$outfile");
print OUT "ensGeneID\tmin\tmax\tgeneSymbol\tgeneCoordinates\n";
foreach my $key (sort keys %GENE){
    my $MAX = $GENE_counts_min{$key}+$GENE_counts_max{$key};
    print OUT "$key\t$GENE_counts_min{$key}\t$MAX\t$GENE{$key}\t$GENE_COORDS{$key}\n";
}

print "got here\n";
