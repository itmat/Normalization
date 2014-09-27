#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl quantify_genes_gnorm.pl <sam2genes output> <genes file> <output file> 

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
while(my $forward = <INFILE2>){
    chomp($forward);
    my $readid;
    #forward read
    my @f = split(/\t/, $forward);
    my $read_id_f = $f[0];
    my $gene_ids_f = $f[2];
    my $gene_syms_f = $f[3];
    my $read_index_f = $f[4];
    my $read_tag_f = $f[5];
    #reverse read
    my $reverse = <INFILE2>;
    my @r = split(/\t/, $reverse);
    my $read_id_r = $r[0];
    my $gene_ids_r = $r[2];
    my $gene_syms_r = $r[3];
    my $read_index_r = $r[4];
    my $read_tag_r = $r[5];
    if (($read_id_f eq $read_id_r) && ($read_index_f eq $read_index_r)){
	$readid = $read_id_f;
#	print "$forward\n$reverse\n";
    }
    else{
	die "ERROR: $input file is not in the correct format.\n";
    }
    # make sure both reads map to at least one gene. 
    if (($gene_ids_f =~ /^$/) || ($gene_ids_r =~ /^$/)){
	next;
    }
    my @bf = split(",", $gene_ids_f);
    my @br = split(",", $gene_ids_r);
    if ((@bf == 1) && (@br == 1)){ #single gene id
	if ($read_tag_f == 1){ #unique mapper
	    if ($gene_ids_f eq $gene_ids_r){ #gene ids equal
		$GENE_counts_min{$gene_ids_f}++;
#		print "ONEGENE\tUNIQUE\tMIN\t$gene_ids_f\n";
	    }
	    else{
#		print "ONEGENE\tUNIQUE\tDIFF_GENEID\tSKIP\n";
	    }
	}
	else{ #non-unique mapper
	    if ($gene_ids_f eq $gene_ids_r){
		my $check = 0;
		#if gene id exists in the $READ{$readid} array, do not increment counter 
		if (exists $READ_NU{$readid}){
		    for (my $j=0; $j<@{$READ_NU{$readid}}; $j++){
			if ($READ_NU{$readid}[$j] eq $gene_ids_f){
			    $check = 1;
			}
		    }
		}
		if ($check == 0){
		    $GENE_counts_max{$gene_ids_f}++;
		    push (@{$READ_NU{$readid}}, $gene_ids_f);
#		    print "NU\tONEGENE\tMAX\t$gene_ids_f\n";
		}
		else{
#		    print "NU\tONEGENE\tSKIP\n";
		}
	    }
	    else{
#		print "NU\tONEGENE\tDIFF_IDS\tSKIP\n";
	    }
	}
    }
    else{ #multiple gene ids
	if ($read_tag_f == 1){ #unique mapper
	    for(my $i=0;$i<@bf;$i++){
		my $check = 0;
		for (my $j=0; $j<@br; $j++){
		    if ($bf[$i] eq $br[$j]){
			$check = 1;
		    }
		}
		if ($check == 1){
		    $GENE_counts_max{$bf[$i]}++;
#		    print "MULTGENE\tUNIQUE\tMAX\t$bf[$i]\n";
		}
		else{
#		    print "MULTGENE\tUNIQUE\tSKIP\n";
		}
	    }
	}
	else{ #non-unique read
	    for(my $i=0;$i<@bf;$i++){
		my $check = 1;
                #if gene id exists in the $READ_NU{$read_id} array, do not increment counter
		if (exists $READ_NU{$readid}){
                    for (my $j=0; $j<@{$READ_NU{$readid}}; $j++){
                        if ($READ_NU{$readid}[$j] eq $bf[$i]){
                           $check = 0;
                        }
                    }
		}
		for (my $k=0; $k<@br; $k++){
                    if ($bf[$i] eq $br[$k]){
                        $check++;
                    }
                }
                if ($check == 2){
                    $GENE_counts_max{$bf[$i]}++;
                    push (@{$READ_NU{$readid}}, $bf[$i]);
#		    print "NON-UNIQUE\tMULTGENE\tMAX\t$bf[$i]\n";
		}
		else{
#		    print "NON-UNIQUE\tMULTGENE\tSKIP\t$bf[$i]\n";
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
