#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<2) {
    die "Usage: perl cleanup.pl <sample dirs> <loc> 

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $norm_dir = $study_dir . "NORMALIZED_DATA/EXON_INTRON_JUNCTION/";
my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers";
my $ig_dir = $norm_dir . "/FINAL_SAM/intergenicmappers";
my $spread_dir = $norm_dir . "/SPREADSHEETS";
my $gnorm_dir = $study_dir . "NORMALIZED_DATA/GENE/";
my $gene_dir = $gnorm_dir . "/FINAL_SAM/";
my $gspread_dir = $gnorm_dir . "/SPREADSHEETS";
my @g;

if (-e "$LOC/one-line.fa"){
    `rm $LOC/one-line.fa`;
}

if (-d $gene_dir){
    @g = glob("$gene_dir/*gene.norm.txt");
    if (@g > 0){
	`rm $gene_dir/*gene.norm.txt`;
    }
    @g = glob("$gene_dir/*gene.norm.genes.txt");
    if (@g > 0){
	`rm $gene_dir/*gene.norm.genes.txt`;
    }
    @g = glob("$gene_dir/*/*gene.norm.txt");
    if (@g > 0){
	`rm $gene_dir/*/*gene.norm.txt`;
    }
    @g = glob("$gene_dir/*/*gene.norm.genes.txt");
    if (@g > 0){
	`rm $gene_dir/*/*gene.norm.genes.txt`;
    }
    @g = glob("$gene_dir/*sam2genes_temp.*");
    if (@g > 0){
	`rm $gene_dir/*sam2genes_temp.*`;
    }
    @g = glob("$gene_dir/*/*sam2genes_temp.*");
    if (@g > 0){
        `rm $gene_dir/*/*sam2genes_temp.*`;
    }
    if (-d "$gene_dir/merged"){
	`rm -r $gene_dir/merged`;
    }
}
if (-d $gnorm_dir){
    @g = glob("$gnorm_dir/file_genequants_minmax*txt");
    if (@g > 0){
	`rm $gnorm_dir/file_genequants_minmax*txt`;
    }
    if (-e "$gnorm_dir/to_filter.txt"){
	`rm $gnorm_dir/to_filter.txt`;
    }
}
if (-d $gspread_dir){
    @g = glob("$gspread_dir/master_list_of_genes_counts_*.txt");
    if (@g > 0){
	`rm $gspread_dir/master_list_of_genes_counts_*.txt`;
    }
}

if (-d $norm_dir){
    @g = glob("$norm_dir/*txt");
    if (@g > 0){
        `rm $norm_dir/*txt`;
    }
    if (-d "$norm_dir/FINAL_SAM/merged"){
	`rm -r $norm_dir/FINAL_SAM/merged`;
    }
}

if (-d $exon_dir){
    if (-d "$exon_dir/sense/"){
	@g = glob("$exon_dir/sense/*.antisense.exonquants");
	if (@g>0){
	    `rm $exon_dir/sense/*.antisense.exonquants`;
	}
    }
    if (-d "$exon_dir/antisense/"){
	@g = glob("$exon_dir/antisense/*.sense.exonquants");
	if (@g>0){
            `rm $exon_dir/antisense/*.sense.exonquants`;
	}
    }
}
if (-d $intron_dir){
    if (-d "$intron_dir/sense/"){
        @g = glob("$intron_dir/sense/*.antisense.intronquants");
        if (@g>0){
            `rm $intron_dir/sense/*.antisense.intronquants`;
        }
    }
    if (-d "$intron_dir/antisense/"){
        @g = glob("$intron_dir/antisense/*.sense.intronquants");
        if (@g>0){
            `rm $intron_dir/antisense/*.sense.intronquants`;
        }
    }
}

if (-d $spread_dir){
    @g = glob("$spread_dir/master_list_of_*_counts_*.txt");
    if (@g > 0){
        `rm $spread_dir/master_list_of_*_counts_*.txt`;
    }
    @g = glob("$spread_dir/annotated_master_list_of_*_counts_*.txt");
    if (@g > 0){
        `rm $spread_dir/annotated_master_list_of_*_counts_*.txt`;
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file $ARGV[0]\n";
while(my $line = <INFILE>){
    chomp($line);
    #remove filtered sam / head files
    if (-d "$LOC/$line/EIJ"){
	`rm -r $LOC/$line/EIJ`;
    }
    if (-d "$LOC/$line/GNORM"){
	`rm -r $LOC/$line/GNORM`;
    }
    if (-e "$LOC/$line/blast.out.1"){
	`rm $LOC/$line/blast.out.*`;
	`rm $LOC/$line/temp.1`;
    }
    @g = glob("$LOC/$line/*_junctions_all.sorted.rum");
    if (@g>0){
	`rm $LOC/$line/*junctions_*`;
    }
}
print "got here\n";
