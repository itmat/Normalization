#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "usage: perl quants2spreadsheet_min_max.pl <sample dirs> <loc> <type of quants file>

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories.
<type of quants file> is the type of quants file. e.g: exonquants, intronquants, genequants

options:
 -novel: set this to label the novel exons/introns
 -stranded : set this if your data are strand-specific

";
if(@ARGV<3) {
    die $USAGE;
}
my $novel = "false";
my $stranded = "false";
for(my $i=3;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq "-novel"){
	$option_found = "true";
	$novel = "true";
    }
    if ($ARGV[$i] eq "-stranded"){
	$stranded = "true";
        $option_found = "true";
    }
    if ($ARGV[$i] eq "-h"){
	$option_found = "true";
	die $USAGE;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;

my $type = $ARGV[2];
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];
my $novellist_exon = "$LOC/$study.list_of_novel_exons.txt";
my $novellist_intron = "$LOC/$study.list_of_novel_introns.txt";
my $list_of_fr = "$LOC/list_of_flanking_regions.txt";

my $last_dir = $fields[@fields-1];
my $norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
    $norm_dir = $norm_dir . "NORMALIZED_DATA/EXON_INTRON_JUNCTION";
}
if ($type =~ /^gene/i){
    $norm_dir = $norm_dir . "NORMALIZED_DATA/GENE";
}
my ($exon_dir_a, $intron_dir_a);
my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers";
if ($stranded eq "true"){
    $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers/sense";
    $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers/sense";
    $exon_dir_a = $norm_dir . "/FINAL_SAM/exonmappers/antisense";
    $intron_dir_a = $norm_dir . "/FINAL_SAM/intronmappers/antisense";
}
my $genequants_dir = $norm_dir . "/FINAL_SAM/";
my $genequants_dir_a;
if ($stranded eq "true"){
    $genequants_dir = $norm_dir . "/FINAL_SAM/sense/";
    $genequants_dir_a = $norm_dir . "/FINAL_SAM/antisense/";
}
my $spread_dir = $norm_dir . "/SPREADSHEETS";
unless (-d $spread_dir){
    `mkdir $spread_dir`;
}
my ($out_MIN, $out_MAX, $sample_name_file);
my ($out_MIN_A, $out_MAX_A, $sample_name_file_a);
if ($type =~ /^exon/i){
    $out_MIN = "$spread_dir/master_list_of_exons_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_exons_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_exonquants_minmax.txt";
    if ($stranded eq "true"){
	$out_MIN = "$spread_dir/master_list_of_exons_counts_MIN.sense.$study.txt";
	$out_MAX = "$spread_dir/master_list_of_exons_counts_MAX.sense.$study.txt";
	$sample_name_file = "$norm_dir/file_exonquants_minmax.sense.txt";
	$out_MIN_A = "$spread_dir/master_list_of_exons_counts_MIN.antisense.$study.txt";
	$out_MAX_A = "$spread_dir/master_list_of_exons_counts_MAX.antisense.$study.txt";
	$sample_name_file_a = "$norm_dir/file_exonquants_minmax.antisense.txt";
    }
}
elsif ($type =~ /^gene/i){
    $out_MIN = "$spread_dir/master_list_of_genes_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_genes_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_minmax.txt";
    if ($stranded eq "true"){
        $out_MIN = "$spread_dir/master_list_of_genes_counts_MIN.sense.$study.txt";
        $out_MAX = "$spread_dir/master_list_of_genes_counts_MAX.sense.$study.txt";
        $sample_name_file = "$norm_dir/file_genequants_minmax.sense.txt";
        $out_MIN_A = "$spread_dir/master_list_of_genes_counts_MIN.antisense.$study.txt";
        $out_MAX_A = "$spread_dir/master_list_of_genes_counts_MAX.antisense.$study.txt";
        $sample_name_file_a = "$norm_dir/file_genequants_minmax.antisense.txt";
    }
}
elsif ($type =~ /^intron/i){
    $out_MIN = "$spread_dir/master_list_of_introns_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_introns_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_intronquants_minmax.txt";
    if ($stranded eq "true"){
	$out_MIN = "$spread_dir/master_list_of_introns_counts_MIN.sense.$study.txt";
	$out_MAX = "$spread_dir/master_list_of_introns_counts_MAX.sense.$study.txt";
	$sample_name_file = "$norm_dir/file_intronquants_minmax.sense.txt";
	$out_MIN_A = "$spread_dir/master_list_of_introns_counts_MIN.antisense.$study.txt";
	$out_MAX_A = "$spread_dir/master_list_of_introns_counts_MAX.antisense.$study.txt";
	$sample_name_file_a = "$norm_dir/file_intronquants_minmax.antisense.txt";
    }
}
else{
    die "ERROR:Please check the type of quants file. It has to be either \"exonquants\" ,\"intronquants\", or \"genequants\".\n\n";
}

if ($type =~ /^exon/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
	open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	if ($stranded ne "true"){
	    print OUT "$exon_dir/$id.exonmappers.norm.exonquants\n";
	}
	if ($stranded eq "true"){
	    print OUT "$exon_dir/$id.exonmappers.norm.sense.exonquants\n";
	    print OUT_A "$exon_dir_a/$id.exonmappers.norm.antisense.exonquants\n";
	}
    }
    close(INFILE);
    close(OUT);
    close(OUT_A);
}
if ($type =~ /^intron/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
        open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        if ($stranded ne "true"){
            print OUT "$intron_dir/$id.intronmappers.norm.intronquants\n";
        }
        if ($stranded eq "true"){
            print OUT "$intron_dir/$id.intronmappers.norm.sense.intronquants\n";
            print OUT_A "$intron_dir_a/$id.intronmappers.norm.antisense.intronquants\n";
        }
    }
}
close(INFILE);
close(OUT);
close(OUT_A);

if ($type =~ /^gene/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
        open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        if ($stranded ne "true"){
            print OUT "$norm_dir/FINAL_SAM/$id.gene.norm.genequants\n";
        }
        if ($stranded eq "true"){
            print OUT "$norm_dir/FINAL_SAM/sense/$id.gene.norm.genefilter.sense.genequants\n";
            print OUT_A "$norm_dir/FINAL_SAM/antisense/$id.gene.norm.genefilter.antisense.genequants\n";
        }
    }
    close(INFILE);
    close(OUT);
    close(OUT_A);
}

open(FILES, $sample_name_file);
my $file = <FILES>;
chomp($file);
close(FILES);

open(INFILE, $file) or die "cannot find file \"$file\"\n";
my $firstline = <INFILE>;
my $rowcnt = 0;
my (@id, @sym, @coord);
while(my $line = <INFILE>) {
    chomp($line);
    if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
    }
    if ($type =~ /^gene/){
	if ($line !~ /^EN/){
	    next;
	}
    }

    my @a = split(/\t/,$line);
    $id[$rowcnt] = $a[0];
    $sym[$rowcnt] = $a[3];
    $coord[$rowcnt] = $a[4];
    $rowcnt++;
}
close(INFILE);
my @ID;
open(FILES, $sample_name_file);
my $filecnt = 0;
my (@DATA_MIN, @DATA_MAX);
while($file = <FILES>) {
    chomp($file);
    my @fields = split("/",$file);
    my $size = @fields;
    my $id = $fields[$size-1];
    $id =~ s/.exonmappers.norm.exonquants//;
    $id =~ s/.intronmappers.norm.intronquants//;
    $id =~ s/.exonmappers.norm.sense.exonquants//;
    $id =~ s/.intronmappers.norm.sense.intronquants//;
    $id =~ s/.gene.norm.genequants//;
    $id =~ s/.gene.norm.genefilter.sense.genequants//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    my $firstline = <INFILE>;
    my $rowcnt = 0;
    while(my $line = <INFILE>) {
	chomp($line);
	my @a = split(/\t/,$line);
	if (($type =~ /^exon/) || ($type =~ /^intron/)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	}
	if ($type =~ /^gene/){
	    if ($line !~ /^EN/){
		next;
	    }
	}
	$DATA_MIN[$filecnt][$rowcnt] = $a[1];
	$DATA_MAX[$filecnt][$rowcnt] = $a[2];
	$rowcnt++;
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

open(OUT_MIN, ">$out_MIN");
open(OUT_MAX, ">$out_MAX");
print OUT_MIN "id";
print OUT_MAX "id";

for(my $i=0; $i<@ID; $i++) {
    print OUT_MIN "\t$ID[$i]";
    print OUT_MAX "\t$ID[$i]";
}
if ($type =~ /^gene/i) {
    print OUT_MIN "\tgeneCoordinate\tgeneSymbol";
    print OUT_MAX "\tgeneCoordinate\tgeneSymbol";
}
if ($type =~ /^exon/i){
    if ($novel eq "true"){
	print OUT_MIN "\tNovelExon";
	print OUT_MAX "\tNovelExon";
    }
}
if ($type =~ /^intron/i){
    if ($novel eq "true"){
	print OUT_MIN "\tNovelIntron/FlankingRegion";
	print OUT_MAX "\tNovelIntron/FlankingRegion";
    }
    else{
	print OUT_MIN "\tFlankingRegion";
	print OUT_MAX "\tFlankingRegion";
    }
}

print OUT_MIN "\n";
print OUT_MAX "\n";
my %NOVEL_E;
my %NOVEL_I;
my %FR;
if ($type =~ /^intron/i){
    open(IN, $list_of_fr) or die "cannot find file \"$list_of_fr\"\n";
    while(my $line =<IN>){
	chomp($line);
	my @a = split(/\t/,$line);
	my $flank = $a[0];
	my $strand = $a[1];
	$FR{$flank} = $strand;
    }
}
if ($novel eq "true"){
    if ($type =~ /^exon/i){
	open(IN, $novellist_exon) or die "cannot find file \"$novellist_exon\"\n";
	while(my $line = <IN>){
	    chomp($line);
	    my @a = split(/\t/,$line);
	    my $exon = $a[0];
	    my $strand = $a[1];
	    $NOVEL_E{$exon} = $strand;
	}
	close(IN);
    }
    if ($type =~ /^intron/i){
	open(IN, $novellist_intron) or die "cannot find file \"$novellist_intron\"\n";
	while(my $line = <IN>){
            chomp($line);
            my @a = split(/\t/,$line);
            my $intron = $a[0];
            my $strand = $a[1];
	    $NOVEL_I{$intron} = $strand;
        }
        close(IN);
    }
}

for(my $i=0; $i<$rowcnt; $i++) {
    if ($type =~ /^exon/i){
	print OUT_MIN "exon:$id[$i]";
	print OUT_MAX "exon:$id[$i]";
    }
    if ($type =~ /^intron/i){
	print OUT_MIN "intron:$id[$i]";
	print OUT_MAX "intron:$id[$i]";
    }
    if ($type =~ /^gene/i){
	print OUT_MIN "gene:$id[$i]";
	print OUT_MAX "gene:$id[$i]";
    }
    for(my $j=0; $j<$filecnt; $j++) {
	print OUT_MIN "\t$DATA_MIN[$j][$i]";
	print OUT_MAX "\t$DATA_MAX[$j][$i]";
    }
    if ($type =~ /^gene/i){
	print OUT_MIN "\t$coord[$i]\t$sym[$i]";
	print OUT_MAX "\t$coord[$i]\t$sym[$i]";
    }	
    if ($type =~ /^exon/i){
	if ($novel eq "true"){
	    if (exists $NOVEL_E{$id[$i]}){
		print OUT_MIN "\tN";
		print OUT_MAX "\tN";
	    }
	    else{
		print OUT_MIN "\t.";
		print OUT_MAX "\t.";
	    }
	}
    }
    if ($type =~ /^intron/i){
	if (exists $FR{$id[$i]}){
	    print OUT_MIN "\tF";
	    print OUT_MAX "\tF";
	}
	else{
	    if ($novel eq "true"){
		if (exists $NOVEL_I{$id[$i]}){
		    print OUT_MIN "\tN";
		    print OUT_MAX "\tN";
		}
		else{
		    print OUT_MIN "\t.";
		    print OUT_MAX "\t.";
		}
	    }
	    else{
		print OUT_MIN "\t.";
		print OUT_MAX "\t.";
	    }
	}
    }
    print OUT_MIN "\n";
    print OUT_MAX "\n";
}
close(OUT_MIN);
close(OUT_MAX);

if ($stranded eq "true"){
    open(FILES, $sample_name_file_a);
    my $file = <FILES>;
    chomp($file);
    close(FILES);
    
    open(INFILE, $file) or die "cannot find file \"$file\"\n";
    my $firstline = <INFILE>;
    my $rowcnt = 0;
    my (@id, @sym, @coord);
    while(my $line = <INFILE>) {
	chomp($line);
	if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	}
	if ($type =~ /^gene/){
	    if ($line !~ /^EN/){
		next;
	    }
	}
	
	my @a = split(/\t/,$line);
	$id[$rowcnt] = $a[0];
	$sym[$rowcnt] = $a[3];
	$coord[$rowcnt] = $a[4];
	$rowcnt++;
    }
    close(INFILE);

    my @ID;
    open(FILES, $sample_name_file_a);
    my $filecnt = 0;
    my (@DATA_MIN, @DATA_MAX);
    while($file = <FILES>) {
	chomp($file);
	my @fields = split("/",$file);
	my $size = @fields;
	my $id = $fields[$size-1];
	$id =~ s/.exonmappers.norm.antisense.exonquants//;
	$id =~ s/.intronmappers.norm.antisense.intronquants//;
	$id =~ s/.gene.norm.genefilter.antisense.genequants//;
	$ID[$filecnt] = $id;
	open(INFILE, $file);
	my $firstline = <INFILE>;
	my $rowcnt = 0;
	while(my $line = <INFILE>) {
	    chomp($line);
	    my @a = split(/\t/,$line);
	    if (($type =~ /^exon/) || ($type =~ /^intron/)){
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
	    }
	    if ($type =~ /^gene/){
		if ($line !~ /^EN/){
		    next;
		}
	    }
	    $DATA_MIN[$filecnt][$rowcnt] = $a[1];
	    $DATA_MAX[$filecnt][$rowcnt] = $a[2];
	    $rowcnt++;
	}
	close(INFILE);
	$filecnt++;
    }
    close(FILES);
    open(OUT_MIN_A, ">$out_MIN_A");
    open(OUT_MAX_A, ">$out_MAX_A");
    print OUT_MIN_A "id";
    print OUT_MAX_A "id";

    for(my $i=0; $i<@ID; $i++) {
	print OUT_MIN_A "\t$ID[$i]";
	print OUT_MAX_A "\t$ID[$i]";
    }
    if ($type =~ /^gene/i) {
	print OUT_MIN_A "\tgeneCoordinate\tgeneSymbol";
	print OUT_MAX_A "\tgeneCoordinate\tgeneSymbol";
    }
    if ($type =~ /^exon/i){
	if ($novel eq "true"){
	    print OUT_MIN_A "\tNovelExon";
	    print OUT_MAX_A "\tNovelExon";
	}
    }
    if ($type =~ /^intron/i){
	if ($novel eq "true"){
	    print OUT_MIN_A "\tNovelIntron/FlankingRegion";
	    print OUT_MAX_A "\tNovelIntron/FlankingRegion";
	}
	else{
	    print OUT_MIN_A "\tFlankingRegion";
	    print OUT_MAX_A "\tFlankingRegion";
	}
    }
    print OUT_MIN_A "\n";
    print OUT_MAX_A "\n";

    for(my $i=0; $i<$rowcnt; $i++) {
	if ($type =~ /^exon/i){
	    print OUT_MIN_A "exon:$id[$i]";
	    print OUT_MAX_A "exon:$id[$i]";
	}
	if ($type =~ /^intron/i){
	    print OUT_MIN_A "intron:$id[$i]";
	    print OUT_MAX_A "intron:$id[$i]";
	}
	if ($type =~ /^gene/i){
	    print OUT_MIN_A "gene:$id[$i]";
	    print OUT_MAX_A "gene:$id[$i]";
	}
	for(my $j=0; $j<$filecnt; $j++) {
	    print OUT_MIN_A "\t$DATA_MIN[$j][$i]";
	    print OUT_MAX_A "\t$DATA_MAX[$j][$i]";
	}
	if ($type =~ /^gene/i){
	    print OUT_MIN_A "\t$coord[$i]\t$sym[$i]";
	    print OUT_MAX_A "\t$coord[$i]\t$sym[$i]";
	}
	if ($type =~ /^exon/i){
	    if ($novel eq "true"){
		if (exists $NOVEL_E{$id[$i]}){
		    print OUT_MIN_A "\tN";
		    print OUT_MAX_A "\tN";
		}
		else{
		    print OUT_MIN_A "\t.";
		    print OUT_MAX_A "\t.";
		}
	    }
	}
	if ($type =~ /^intron/i){
	    if (exists $FR{$id[$i]}){
		print OUT_MIN_A "\tF";
		print OUT_MAX_A "\tF";
	    }
	    else{
		if ($novel eq "true"){
		    if (exists $NOVEL_I{$id[$i]}){
			print OUT_MIN_A "\tN";
			print OUT_MAX_A "\tN";
		    }
		    else{
			print OUT_MIN_A "\t.";
			print OUT_MAX_A "\t.";
		    }
		}
		else{
		    print OUT_MIN_A "\t.";
		    print OUT_MAX_A "\t.";
		}
	    }
	}
	print OUT_MIN_A "\n";
	print OUT_MAX_A "\n";
    }
    close(OUT_MIN_A);
    close(OUT_MAX_A);
}
print "got here\n";

