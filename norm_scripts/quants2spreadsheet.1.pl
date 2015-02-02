#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE = "usage: perl quants2spreadsheet.1.pl <file names> <loc> <type of quants file> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories
<type of quants file> is the type of quants file (e.g: exonquants, intronquants, genequants)

option:
 -NU: set this if you want to use non-unique quants, otherwise by default it will 
      use unique quants files as input

 -novel : set this to label the novel exons/introns

 -stranded : set this if your data are strand-specific.

";
if(@ARGV<3) {
    die $USAGE;
}
my $stranded = "false";
my $nuonly = 'false';
my $novel = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $arg_recognized = 'false';
    if($ARGV[$i] eq '-NU') {
	$nuonly = 'true';
	$arg_recognized = 'true';
    }
    if ($ARGV[$i] eq '-stranded'){
	$arg_recognized = "true";
	$stranded = "true";
    }
    if ($ARGV[$i] eq "-novel"){
        $arg_recognized = "true";
        $novel = "true";
    }
    if ($ARGV[$i] eq "-h"){
        $arg_recognized = "true";
        die $USAGE;
    }
    if($arg_recognized eq 'false') {
	die "arg \"$ARGV[$i]\" not recognized.\n";
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

my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/notexonmappers";
my $spread_dir = $norm_dir . "/SPREADSHEETS";
my ($exon_dir_a, $intron_dir_a);
if ($stranded eq "true"){
    $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers/sense";
    $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers/sense";
    $exon_dir_a = $norm_dir . "/FINAL_SAM/exonmappers/antisense";
    $intron_dir_a = $norm_dir . "/FINAL_SAM/intronmappers/antisense";
}

unless (-d $spread_dir){
    `mkdir -p $spread_dir`;
}
my ($out, $sample_name_file, $out_min, $out_max);
my ($out_a, $sample_name_file_a, $out_min_a, $out_max_a);
if ($type =~ /^exon/i){
    $out = "$spread_dir/master_list_of_exons_counts_u.$study.txt";
    $sample_name_file = "$norm_dir/file_exonquants_u.txt";
    if ($stranded eq "true"){
	$out = "$spread_dir/master_list_of_exons_counts_u.sense.$study.txt";
	$sample_name_file = "$norm_dir/file_exonquants_u.sense.txt";
	$out_a = "$spread_dir/master_list_of_exons_counts_u.antisense.$study.txt";
	$sample_name_file_a = "$norm_dir/file_exonquants_u.antisense.txt";
    }
    if ($nuonly eq "true"){
	$out =~ s/_u.$study.txt/_nu.$study.txt/;
	$sample_name_file =~ s/_u.txt/_nu.txt/;
	$out =~ s/_u.sense.$study.txt/_nu.sense.$study.txt/;
	$sample_name_file =~ s/_u.sense.txt/_nu.sense.txt/;
	$out_a =~ s/_u.antisense.$study.txt/_nu.antisense.$study.txt/;
	$sample_name_file_a =~ s/_u.antisense.txt/_nu.antisense.txt/;
    }
}
elsif ($type =~ /^gene/i){
    $out_min = "$spread_dir/master_list_of_genes_counts_u.MIN.$study.txt";
    $out_max = "$spread_dir/master_list_of_genes_counts_u.MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_u.txt";
    if ($stranded eq "true"){
	$out_min = "$spread_dir/master_list_of_genes_counts_u.MIN.sense.$study.txt";
	$out_max = "$spread_dir/master_list_of_genes_counts_u.MAX.sense.$study.txt";
	$out_min_a = "$spread_dir/master_list_of_genes_counts_u.MIN.antisense.$study.txt";
	$out_max_a = "$spread_dir/master_list_of_genes_counts_u.MAX.antisense.$study.txt";
	$sample_name_file = "$norm_dir/file_genequants_u.sense.txt";
	$sample_name_file_a = "$norm_dir/file_genequants_u.antisense.txt";
    }
    if ($nuonly eq "true"){
        $out_min =~ s/_u.MIN/_nu.MIN/;
        $out_max =~ s/_u.MAX/_nu.MAX/;
        $sample_name_file =~ s/_u.txt/_nu.txt/;
        $sample_name_file =~ s/_u.sense.txt/_nu.sense.txt/;
	$out_min_a =~ s/_u.MIN/_nu.MIN/;
	$out_max_a = s/_u.MAX/_nu.MAX/;
	$sample_name_file_a =~ s/_u.antisense.txt/_nu.antisense.txt/;
    }
}
elsif ($type =~ /^intron/i){
    $out = "$spread_dir/master_list_of_introns_counts_u.$study.txt";
    $sample_name_file = "$norm_dir/file_intronquants_u.txt";
    if ($stranded eq "true"){
        $out = "$spread_dir/master_list_of_introns_counts_u.sense.$study.txt";
        $sample_name_file = "$norm_dir/file_intronquants_u.sense.txt";
        $out_a = "$spread_dir/master_list_of_introns_counts_u.antisense.$study.txt";
        $sample_name_file_a = "$norm_dir/file_intronquants_u.antisense.txt";
    }
    if ($nuonly eq "true"){
        $out =~ s/_u.$study.txt/_nu.$study.txt/;
        $sample_name_file =~ s/_u.txt/_nu.txt/;
	$out =~ s/_u.sense.$study.txt/_nu.sense.$study.txt/;
        $sample_name_file =~ s/_u.sense.txt/_nu.sense.txt/;
        $out_a =~ s/_u.antisense.$study.txt/_nu.antisense.$study.txt/;
        $sample_name_file_a =~ s/_u.antisense.txt/_nu.antisense.txt/;
    }
}
else{
    die "ERROR:Please check the type of quants file. It has to be either \"exonquants\", \"intronquants\", \"genequants\".\n\n";
}


if($type =~ /^exon/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
	open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	if($nuonly eq "false"){
	    if ($stranded ne "true"){
		print OUT "$exon_dir/$id.exonmappers.norm_u.exonquants\n";
	    }
	    if ($stranded eq "true"){
		print OUT "$exon_dir/$id.exonmappers.norm_u.sense.exonquants\n";
		print OUT_A "$exon_dir_a/$id.exonmappers.norm_u.antisense.exonquants\n";
	    }
	}
	if($nuonly eq "true"){
            if ($stranded ne "true"){
                print OUT "$exon_dir/$id.exonmappers.norm_nu.exonquants\n";
            }
            if ($stranded eq "true"){
                print OUT "$exon_dir/$id.exonmappers.norm_nu.sense.exonquants\n";
                print OUT_A "$exon_dir_a/$id.exonmappers.norm_nu.antisense.exonquants\n";
            }
	}
    }
    close(OUT);
    close(OUT_A);
    close(INFILE);
}

if($type =~ /^intron/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
        open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        if($nuonly eq "false"){
            if ($stranded ne "true"){
                print OUT "$intron_dir/$id.intronmappers.norm_u.intronquants\n";
            }
            if ($stranded eq "true"){
                print OUT "$intron_dir/$id.intronmappers.norm_u.sense.intronquants\n";
                print OUT_A "$intron_dir_a/$id.intronmappers.norm_u.antisense.intronquants\n";
            }
        }
        if($nuonly eq "true"){
            if ($stranded ne "true"){
                print OUT "$intron_dir/$id.intronmappers.norm_nu.intronquants\n";
            }
            if ($stranded eq "true"){
                print OUT "$intron_dir/$id.intronmappers.norm_nu.sense.intronquants\n";
                print OUT_A "$intron_dir_a/$id.intronmappers.norm_nu.antisense.intronquants\n";
            }
        }
    }
    close(OUT);
    close(OUT_A);
    close(INFILE);
}


if ($type =~ /^gene/i){

    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    if ($stranded eq "true"){
        open(OUT_A, ">$sample_name_file_a");
    }
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        if($nuonly eq "false"){
            if ($stranded ne "true"){
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm_u.genefilter.genequants\n";
            }
            if ($stranded eq "true"){
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm_u.genefilter.sense.genequants\n";
                print OUT_A "$norm_dir/FINAL_SAM/$id.gene.norm_u.genefilter.antisense.genequants\n";
            }
        }
        if($nuonly eq "true"){
            if ($stranded ne "true"){
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm_nu.genefilter.genequants\n";
            }
            if ($stranded eq "true"){
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm_nu.genefilter.sense.genequants\n";
                print OUT_A "$norm_dir/FINAL_SAM/$id.gene.norm_nu.genefilter.antisense.genequants\n";
            }
        }
    }
    close(OUT);
    close(OUT_A);
    close(INFILE);
}
close(INFILE);
close(OUT);

open(FILES, $sample_name_file);
my $file = <FILES>;
close(FILES);

open(INFILE, $file) or die "cannot find file \"$file\"\n";
my $firstline = <INFILE>;
my $rowcnt = 0;
my (@id, @sym, @coord);
while(my $line = <INFILE>) {
    chomp($line);
    if ($type =~ /^gene/i){
	if ($line !~ /^EN/){
	    next;
	}
    }
    if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
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

open(FILES, $sample_name_file);
my $filecnt = 0;
my (@ID, @DATA, @DATA_MIN, @DATA_MAX);
while($file = <FILES>) {
    chomp($file);
    my @fields = split("/",$file);
    my $size = @fields;
    my $id = $fields[$size-1];
    $id =~ s/.exonmappers.norm_u.exonquants//;
    $id =~ s/.exonmappers.norm_nu.exonquants//;
    $id =~ s/.intronmappers.norm_u.intronquants//;
    $id =~ s/.intronmappers.norm_nu.intronquants//;
    $id =~ s/.exonmappers.norm_u.sense.exonquants//;
    $id =~ s/.exonmappers.norm_nu.sense.exonquants//;
    $id =~ s/.intronmappers.norm_u.sense.intronquants//;
    $id =~ s/.intronmappers.norm_nu.sense.intronquants//;
    $id =~ s/.gene.norm_u.genefilter.sense.genequants//;
    $id =~ s/.gene.norm_u.genefilter.genequants//;
    $id =~ s/.gene.norm_nu.genefilter.sense.genequants//;
    $id =~ s/.gene.norm_nu.genefilter.genequants//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    my $firstline = <INFILE>;
    my $rowcnt = 0;
    while(my $line = <INFILE>) {
	chomp($line);
	my @a = split(/\t/,$line);
	if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	    $DATA[$filecnt][$rowcnt] = $a[1];
	}
	if ($type =~ /^gene/i){
	    if ($line !~ /^EN/){
		next;
	    }
	    $DATA_MIN[$filecnt][$rowcnt] = $a[1];
	    $DATA_MAX[$filecnt][$rowcnt] = $a[2];
	}
	$rowcnt++;
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);
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

if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
    open(OUTFILE, ">$out");
    print OUTFILE "id";
    for(my $i=0; $i<@ID; $i++) {
	print OUTFILE "\t$ID[$i]";
    }
    if ($type =~ /^exon/i){
	if ($novel eq "true"){
	    print OUTFILE "\tNovelExon";
	}
    }
    if ($type =~ /^intron/i){
	if ($novel eq "true"){
	    print OUTFILE "\tNovelIntron/FlankingRegion";
	}
	else{
	    print OUTFILE "\tFlankingRegion";
	}
    }
    print OUTFILE "\n";
    for(my $i=0; $i<$rowcnt; $i++) {
	if ($type =~ /^exon/i){
	    print OUTFILE "exon:$id[$i]";
	}
	if ($type =~ /^intron/i){
	    print OUTFILE "intron:$id[$i]";
	}
	for(my $j=0; $j<$filecnt; $j++) {
	    print OUTFILE "\t$DATA[$j][$i]";
	}
	if ($type =~ /^exon/i){
	    if ($novel eq "true"){
		if (exists $NOVEL_E{$id[$i]}){
		    print OUTFILE "\tN";
		}
		else{
		    print OUTFILE "\t.";
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
	print OUTFILE "\n";
    }
}
close(OUTFILE);



if ($type =~ /^gene/i){
    open(OUT_MIN, ">$out_min");
    open(OUT_MAX, ">$out_max");
    print OUT_MIN "id";
    print OUT_MAX "id";
    for(my $i=0; $i<@ID; $i++) {
        print OUT_MIN "\t$ID[$i]";
        print OUT_MAX "\t$ID[$i]";
    }
    print OUT_MIN "\tgeneCoordinate\tgeneSymbol\n";
    print OUT_MAX "\tgeneCoordinate\tgeneSymbol\n";
    for(my $i=0; $i<$rowcnt; $i++) {
	print OUT_MIN "gene:$id[$i]";
	print OUT_MAX "gene:$id[$i]";
        for(my $j=0; $j<$filecnt; $j++) {
            print OUT_MIN "\t$DATA_MIN[$j][$i]";
            print OUT_MAX "\t$DATA_MAX[$j][$i]";
	}
	print OUT_MIN "\t$coord[$i]\t$sym[$i]\n";
	print OUT_MAX "\t$coord[$i]\t$sym[$i]\n";
    }
    close(OUT_MIN);
    close(OUT_MAX);
}
#antisense
if ($stranded eq "true"){
    open(FILES, $sample_name_file_a);
    my $file = <FILES>;
    close(FILES);
    
    open(INFILE, $file) or die "cannot find file \"$file\"\n";
    my $firstline = <INFILE>;
    my $rowcnt = 0;
    my (@id, @sym, @coord);
    while(my $line = <INFILE>) {
	chomp($line);
	if ($type =~ /^gene/i){
	    if ($line !~ /^EN/){
		next;
	    }
	}
	if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
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
    open(FILES, $sample_name_file_a);
    my $filecnt = 0;
    my (@ID, @DATA, @DATA_MIN, @DATA_MAX);
    while($file = <FILES>) {
	chomp($file);
	my @fields = split("/",$file);
	my $size = @fields;
	my $id = $fields[$size-1];
	$id =~ s/.exonmappers.norm_u.exonquants//;
	$id =~ s/.exonmappers.norm_nu.exonquants//;
	$id =~ s/.intronmappers.norm_u.intronquants//;
	$id =~ s/.intronmappers.norm_nu.intronquants//;
	$id =~ s/.exonmappers.norm_u.sense.exonquants//;
	$id =~ s/.exonmappers.norm_nu.sense.exonquants//;
	$id =~ s/.intronmappers.norm_u.sense.intronquants//;
	$id =~ s/.intronmappers.norm_nu.sense.intronquants//;
	$id =~ s/.gene.norm_nu.genefilter.antisense.genequants//;
	$id =~ s/.gene.norm_u.genefilter.antisense.genequants//;
	$ID[$filecnt] = $id;
	open(INFILE, $file);
	my $firstline = <INFILE>;
	my $rowcnt = 0;
	while(my $line = <INFILE>) {
	    chomp($line);
	    my @a = split(/\t/,$line);
	    if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
		if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		    next;
		}
		$DATA[$filecnt][$rowcnt] = $a[1];
	    }
	    if ($type =~ /^gene/i){
		if ($line !~ /^EN/){
		    next;
		}
		$DATA_MIN[$filecnt][$rowcnt] = $a[1];
		$DATA_MAX[$filecnt][$rowcnt] = $a[2];
	    }
	    $rowcnt++;
	}
	close(INFILE);
	$filecnt++;
    }
    close(FILES);
    if (($type =~ /^exon/i) || ($type =~ /^intron/i)){
	open(OUTFILE, ">$out_a");
	print OUTFILE "id";
	for(my $i=0; $i<@ID; $i++) {
	    print OUTFILE "\t$ID[$i]";
	}
	if ($type =~ /^exon/i){
	    if ($novel eq "true"){
		print OUTFILE "\tNovelExon";
	    }
	}
	if ($type =~ /^intron/i){
	    if ($novel eq "true"){
		print OUTFILE "\tNovelIntron/FlankingRegion";
	    }
	    else{
		print OUTFILE "\tFlankingRegion";
	    }
	}
	print OUTFILE "\n";
	for(my $i=0; $i<$rowcnt; $i++) {
	    if ($type =~ /^exon/i){
		print OUTFILE "exon:$id[$i]";
	    }
	    if ($type =~ /^intron/i){
		print OUTFILE "intron:$id[$i]";
	    }
	    for(my $j=0; $j<$filecnt; $j++) {
		print OUTFILE "\t$DATA[$j][$i]";
	    }
	    if ($type =~ /^exon/i){
		if ($novel eq "true"){
		    if (exists $NOVEL_E{$id[$i]}){
			print OUTFILE "\tN";
		    }
		    else{
			print OUTFILE "\t.";
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
	    print OUTFILE "\n";
	}
    }
}
close(OUT_MIN);
close(OUT_MAX);
print "got here\n";
