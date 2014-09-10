#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "usage: perl quants2spreadsheet_min_max.pl <sample dirs> <loc> <type of quants file>

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories.
<type of quants file> is the type of quants file. e.g: exonquants, intronquants, genequants

options:
 -novelexon <file> : provide full path of list of novel exons file with this option to label the exons

";
if(@ARGV<3) {
    die $USAGE;
}
my ($option_found, $novellist);
my $novelexon = "false";
for(my $i=3;$i<@ARGV;$i++){
    $option_found = "false";
    if ($ARGV[$i] eq "-novelexon"){
	$option_found = "true";
	$novelexon = "true";
	$novellist = $ARGV[$i+1];
	if ($novellist =~ /^$/){
	    die "please provide a list of novel exons\n";
	}
	$i++;
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
my $last_dir = $fields[@fields-1];
my $norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";
my $exon_dir = $norm_dir . "/exonmappers";
my $nexon_dir = $norm_dir . "/notexonmappers";
my $genequants_dir = $norm_dir . "/FINAL_SAM/MERGED";
my $spread_dir = $norm_dir . "/SPREADSHEETS";
my $gnorm_dir = $norm_dir. "/GENE_NORM";
unless (-d $spread_dir){
    `mkdir $spread_dir`;
}
my ($out_MIN, $out_MAX, $sample_name_file, $merged_dir);
if ($type =~ /^exon/){
    $out_MIN = "$spread_dir/master_list_of_exons_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_exons_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_exonquants_minmax.txt";
}
elsif ($type =~ /^gene/){
    $out_MIN = "$spread_dir/master_list_of_genes_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_genes_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_minmax.txt";
}
elsif ($type =~ /^gnorm/){
    $out_MIN = "$spread_dir/master_list_of_genes_counts_MIN.GNORM.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_genes_counts_MAX.GNORM.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_minmax.GNORM.txt";
}
elsif ($type =~ /^intron/){
    $out_MIN = "$spread_dir/master_list_of_introns_counts_MIN.$study.txt";
    $out_MAX = "$spread_dir/master_list_of_introns_counts_MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_intronquants_minmax.txt";
    $merged_dir = $nexon_dir . "/MERGED";
    unless (-d $merged_dir){
	`mkdir $merged_dir`;
    }
}
else{
    die "ERROR:Please check the type of quants file. It has to be either \"exonquants\" ,\"intronquants\", or \"genequants\".\n\n";
}

if ($type =~ /^exon/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while (my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	print OUT "$exon_dir/MERGED/$id.exonmappers.norm_exonquants\n";
    }
}
close(INFILE);
close(OUT);

if ($type =~ /^gene/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while (my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	print OUT "$norm_dir/FINAL_SAM/MERGED/$id.FINAL.norm.genequants\n";
    }
}
close(INFILE);
close(OUT);

if ($type =~ /^gnorm/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        print OUT "$gnorm_dir/MERGED/$id.GNORM.genequants\n";
    }
}
close(INFILE);
close(OUT);

if ($type =~ /^intron/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    while(my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	my $Unique = "$nexon_dir/Unique/$id.intronmappers.norm_u_intronquants";
	my $NU = "$nexon_dir/NU/$id.intronmappers.norm_nu_intronquants";
	my $Unique_no_header = $Unique . "_no_header";
	my $NU_no_header = $NU . "_no_header";
	my $NEW_quants = "$merged_dir/$id.intronquants_merged";

	open(FILE1, "<$Unique") or die "cannot find file '$Unique'\n";
	my @lines = <FILE1>;
	close(FILE1);

	open(FILE1_new, ">$Unique_no_header");
	foreach $line (@lines){
	    print FILE1_new $line unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(FILE1_new);

	open(FILE2, "<$NU") or die "cannot find file '$NU'\n";
	my @lines2 = <FILE2>;
	close(FILE2);

	open(FILE2_new, ">$NU_no_header");
	foreach my $line2 (@lines2){
	    print FILE2_new $line2 unless ($line2 !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(FILE2_new);
    
	open(File1, $Unique_no_header);
	open(File2, $NU_no_header);
	open(OUT, ">$NEW_quants");
	print OUT "feature\tmin\tmax\n";
	while (!eof File1 and !eof File2){
	    my $line_U = <File1>;
	    my $line_NU = <File2>;
	    chomp($line_U);
	    chomp($line_NU);

	    my @a1 = split(/\t/, $line_U);
	    my $feature1 = $a1[0];
	    my $min = $a1[1];

	    my @a2 = split(/\t/, $line_NU);
	    my $feature2 = $a2[0];
	    my $nu_cnt = $a2[1];

	    my $max = $min + $nu_cnt;
	    my $feature_min_max;
	    if ($feature1 eq $feature2){
		$feature_min_max = "$feature1\t$min\t$max\n";
	    }
	    else{
		$feature_min_max = "not equal!!!!";
	    }
	    print OUT $feature_min_max;
	}
	close(OUT);
	close(File1);
	close(File2);
    }
    close(INFILE);
#    `rm $nexon_dir/Unique/*no_header $nexon_dir/NU/*no_header`;
    open(INFILE, $ARGV[0]);
    open(OUT, ">$sample_name_file");
    while (my $line = <INFILE>){
	chomp($line);
	my $id = $line;
	print OUT "$merged_dir/$id.intronquants_merged\n";
    }
}
close(INFILE);
close(OUT);
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
    if (($type =~ /^exon/) || ($type =~ /^intron/)){
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
    }
    if (($type =~ /^gene/)|| ($type =~ /^gnorm/)){
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
    $id =~ s/.exonmappers.norm_exonquants//;
    $id =~ s/.intronquants_merged//;
    $id =~ s/.FINAL.norm.genequants//;
    $id =~ s/.GNORM.genequants//;
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
	if (($type =~ /^gene/)|| ($type =~ /^gnorm/)){
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
if (($type =~ /^gene/) || ($type =~ /^gnorm/)){
    print OUT_MIN "\tgeneCoordinate\tgeneSymbol";
    print OUT_MAX "\tgeneCoordinate\tgeneSymbol";
}
if ($type =~ /^exon/){
    if ($novelexon eq "true"){
	print OUT_MIN "\tNovelExon";
	print OUT_MAX "\tNovelExon";
    }
}
print OUT_MIN "\n";
print OUT_MAX "\n";
my %NOVEL;
if ($novelexon eq "true"){
    open(IN, $novellist) or die "cannot find file \"$novellist\"\n";
    while(my $line = <IN>){
	chomp($line);
	$NOVEL{$line} = 1;
    }
    close(IN);
}

for(my $i=0; $i<$rowcnt; $i++) {
    if ($type =~ /^exon/){
	print OUT_MIN "exon:$id[$i]";
	print OUT_MAX "exon:$id[$i]";
    }
    if ($type =~ /^intron/){
	print OUT_MIN "intron:$id[$i]";
	print OUT_MAX "intron:$id[$i]";
    }
    if (($type =~ /^gene/)||($type =~ /^gnorm/)){
	print OUT_MIN "gene:$id[$i]";
	print OUT_MAX "gene:$id[$i]";
    }
    for(my $j=0; $j<$filecnt; $j++) {
	print OUT_MIN "\t$DATA_MIN[$j][$i]";
	print OUT_MAX "\t$DATA_MAX[$j][$i]";
    }
    if (($type =~ /^gene/)|| ($type =~ /^gnorm/)){
	print OUT_MIN "\t$coord[$i]\t$sym[$i]";
	print OUT_MAX "\t$coord[$i]\t$sym[$i]";
    }	
    if ($type =~ /^exon/){
	if ($novelexon eq "true"){
	    if (exists $NOVEL{$id[$i]}){
		print OUT_MIN "\tN";
		print OUT_MAX "\tN";
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
print "got here\n";

