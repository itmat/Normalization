#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE = "usage: perl quants2spreadsheet.1.pl <file names> <loc> <type of quants file> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories
<type of quants file> is the type of quants file (e.g: exonquants, intronquants, genequants, intergenicquants)

option: 
 -normdir <s>
 -NU: set this if you want to use non-unique quants, otherwise by default it will 
      use unique quants files as input

 -novel : set this to label the novel exons/introns

 -stranded : set this if your data are strand-specific.

 -filter_highexp : set this to label highexpressers
 
 -h : print usage

";
if(@ARGV<3) {
    die $USAGE;
}
my $stranded = "false";
my $nuonly = 'false';
my $novel = "false";
my $filter = "false";
my $normdir = "";
my $ncnt =0;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=3; $i<@ARGV; $i++) {
    my $arg_recognized = 'false';
    if ($ARGV[$i] eq "-filter_highexp"){
        $arg_recognized = "true";
        $filter = "true";
    }
    if($ARGV[$i] eq '-NU') {
	$nuonly = 'true';
	$arg_recognized = 'true';
    }
    if($ARGV[$i] eq '-normdir') {
        $arg_recognized = 'true';
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if ($ARGV[$i] eq '-stranded'){
	$arg_recognized = "true";
	$stranded = "true";
    }
    if ($ARGV[$i] eq "-novel"){
        $arg_recognized = "true";
        $novel = "true";
    }
    if($arg_recognized eq 'false') {
	die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}
if ($ncnt ne '1'){
    die "please specify -normdir path\n";
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
my $norm_dir = "";
my $HE_GENE = "$LOC/high_expressers_gene.txt";
my $HE_EXON = "$LOC/high_expressers_exon.txt";
my $HE_INTRON = "$LOC/high_expressers_intron.txt";
my ($HE_GENE_A, $HE_EXON_A, $HE_INTRON_A);
if ($stranded eq "true"){
    $HE_GENE = "$LOC/high_expressers_gene_sense.txt";
    $HE_EXON = "$LOC/high_expressers_exon_sense.txt";
    $HE_INTRON = "$LOC/high_expressers_intron_sense.txt";
    $HE_GENE_A = "$LOC/high_expressers_gene_antisense.txt";
    $HE_EXON_A = "$LOC/high_expressers_exon_antisense.txt";
    $HE_INTRON_A = "$LOC/high_expressers_intron_antisense.txt";
}

if (($type =~ /^exon/i) || ($type =~ /^intron/i) || ($type =~ /^intergenic/i)){
    $norm_dir = "$normdir/EXON_INTRON_JUNCTION";
}
if ($type =~ /^gene/i){
    $norm_dir = "$normdir/GENE";
}

my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers";
my $ig_dir = $norm_dir . "/FINAL_SAM/intergenicmappers";
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
    $out = "$spread_dir/master_list_of_exon_counts_MIN.$study.txt";
    $sample_name_file = "$norm_dir/file_exonquants.txt";
    if ($stranded eq "true"){
	$out = "$spread_dir/master_list_of_exon_counts_MIN.sense.$study.txt";
	$sample_name_file = "$norm_dir/file_exonquants.sense.txt";
	$out_a = "$spread_dir/master_list_of_exon_counts_MIN.antisense.$study.txt";
	$sample_name_file_a = "$norm_dir/file_exonquants.antisense.txt";
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
    $out_min = "$spread_dir/master_list_of_gene_counts_u.MIN.$study.txt";
    $out_max = "$spread_dir/master_list_of_gene_counts_u.MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_u.txt";
    if ($stranded eq "true"){
	$out_min = "$spread_dir/master_list_of_gene_counts_u.MIN.sense.$study.txt";
	$out_max = "$spread_dir/master_list_of_gene_counts_u.MAX.sense.$study.txt";
	$out_min_a = "$spread_dir/master_list_of_gene_counts_u.MIN.antisense.$study.txt";
	$out_max_a = "$spread_dir/master_list_of_gene_counts_u.MAX.antisense.$study.txt";
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
    $out = "$spread_dir/master_list_of_intron_counts_MIN.$study.txt";
    $sample_name_file = "$norm_dir/file_intronquants.txt";
    if ($stranded eq "true"){
        $out = "$spread_dir/master_list_of_intron_counts_MIN.sense.$study.txt";
        $sample_name_file = "$norm_dir/file_intronquants.sense.txt";
        $out_a = "$spread_dir/master_list_of_intron_counts_MIN.antisense.$study.txt";
        $sample_name_file_a = "$norm_dir/file_intronquants.antisense.txt";
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
elsif ($type =~ /^intergenic/i){
    $out = "$spread_dir/master_list_of_intergenic_counts_MIN.$study.txt";
    $sample_name_file = "$norm_dir/file_intergenicquants.txt";
    if ($nuonly eq "true"){
        $out =~ s/_u.$study.txt/_nu.$study.txt/;
        $sample_name_file =~ s/_u.txt/_nu.txt/;
    }
}
else{
    die "ERROR:Please check the type of quants file. It has to be either \"exonquants\", \"intronquants\", \"intergenicquants\", \"genequants\".\n\n";
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
		print OUT "$exon_dir/$id.exonmappers.norm.exonquants\n";
	    }
	    if ($stranded eq "true"){
		print OUT "$exon_dir/$id.exonmappers.norm.sense.exonquants\n";
		print OUT_A "$exon_dir_a/$id.exonmappers.norm.antisense.exonquants\n";
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
                print OUT "$intron_dir/$id.intronmappers.norm.intronquants\n";
            }
            if ($stranded eq "true"){
                print OUT "$intron_dir/$id.intronmappers.norm.sense.intronquants\n";
                print OUT_A "$intron_dir_a/$id.intronmappers.norm.antisense.intronquants\n";
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
if($type =~ /^intergenic/i){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while (my $line = <INFILE>){
        chomp($line);
        my $id = $line;
        if($nuonly eq "false"){
	    print OUT "$ig_dir/$id.intergenicmappers.norm.intergenicquants\n";
        }
        if($nuonly eq "true"){
	    print OUT "$ig_dir/$id.intergenicmappers.norm_nu.intergenicquants\n";
        }
    }
    close(OUT);
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
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm.genequants\n";
            }
            if ($stranded eq "true"){
                print OUT "$norm_dir/FINAL_SAM/sense/$id.gene.norm_u.genefilter.sense.genequants";
                print OUT_A "$norm_dir/FINAL_SAM/antisense/$id.gene.norm_u.genefilter.antisense.genequants";
            }
        }
        if($nuonly eq "true"){
            if ($stranded ne "true"){
                print OUT "$norm_dir/FINAL_SAM/$id.gene.norm.genequants";
            }
            if ($stranded eq "true"){
                print OUT "$norm_dir/FINAL_SAM/sense/$id.gene.norm_nu.genefilter.sense.genequants\n";
                print OUT_A "$norm_dir/FINAL_SAM/antisense/$id.gene.norm_nu.genefilter.antisense.genequants\n";
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
chomp($file);
close(FILES);

open(INFILE, $file) or die "cannot find file \"$file\"\n";
my $firstline = <INFILE>;
my $rowcnt = 0;
my (@id, @sym, @coord);
while(my $line = <INFILE>) {
    chomp($line);
    if ($type =~ /^gene/i){
	if ($line =~ /^ensGeneID/){
	    next;
	}
    }
    if (($type =~ /^exon/i) || ($type =~ /^intron/i) || ($type =~ /intergenic/i)){
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
    $id =~ s/.intergenicmappers.norm_u.intergenicquants//;
    $id =~ s/.intergenicmappers.norm_nu.intergenicquants//;
    $id =~ s/.intergenicmappers.norm.intergenicquants//;
    $id =~ s/.intronmappers.norm.intronquants//;
    $id =~ s/.exonmappers.norm.exonquants//;
    $id =~ s/.exonmappers.norm_u.sense.exonquants//;
    $id =~ s/.exonmappers.norm_nu.sense.exonquants//;
    $id =~ s/.intronmappers.norm_u.sense.intronquants//;
    $id =~ s/.intronmappers.norm_nu.sense.intronquants//;
    $id =~ s/.gene.norm_u.genefilter.sense.genequants//;
    $id =~ s/.gene.norm_u.genefilter.genequants//;
    $id =~ s/.gene.norm_nu.genefilter.sense.genequants//;
    $id =~ s/.gene.norm_nu.genefilter.genequants//;
    $id =~ s/.gene.norm.genequants//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    my $firstline = <INFILE>;
    my $rowcnt = 0;
    while(my $line = <INFILE>) {
	chomp($line);
	my @a = split(/\t/,$line);
	if (($type =~ /^exon/i) || ($type =~ /^intron/i) || ($type =~ /^intergenic/i)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	    $DATA[$filecnt][$rowcnt] = $a[1];
	}
	if ($type =~ /^gene/i){
	    if ($line =~ /^ensGeneID/){
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
my (%HIGH_G, %HIGH_E, %HIGH_I, %HIGH_GA, %HIGH_EA, %HIGH_IA);
if ($filter eq "true"){
    if ($type =~ /^exon/i){
        if (-e "$HE_EXON"){
            open(IN, $HE_EXON);
            while(my $line = <IN>){
                chomp($line);
                my @a = split(/\t/,$line);
                my $exon = $a[0];
                $HIGH_E{$exon} = 1;
            }
            close(IN);
        }
	if ($stranded eq "true"){
	    if (-e "$HE_EXON_A"){
		open(IN, $HE_EXON_A);
		while(my $line = <IN>){
		    chomp($line);
		    my @a = split(/\t/,$line);
		    my $exon = $a[0];
		    $HIGH_EA{$exon} = 1;
		}
		close(IN);
	    }
	}
    }
    if ($type =~ /^intron/i){
        if (-e "$HE_INTRON"){
            open(IN, $HE_INTRON);
            while(my $line = <IN>){
                chomp($line);
                my @a = split(/\t/,$line);
                my $intron = $a[0];
                $HIGH_I{$intron} = 1;
            }
            close(IN);
        }
	if ($stranded eq "true"){
	    if (-e "$HE_INTRON_A"){
		open(IN, $HE_INTRON_A);
		while(my $line = <IN>){
		    chomp($line);
		    my @a = split(/\t/,$line);
		    my $intron = $a[0];
		    $HIGH_IA{$intron} = 1;
		}
		close(IN);
	    }
	}
    }
    if ($type =~ /^gene/i){
        if (-e "$HE_GENE"){
            open(IN, $HE_GENE);
            while(my $line = <IN>){
                chomp($line);
                my @a = split(/\t/,$line);
                my $gene = $a[0];
                $HIGH_G{$gene} = 1;
            }
            close(IN);
        }
        if ($stranded eq "true"){
            if (-e "$HE_GENE_A"){
                open(IN, $HE_GENE_A);
                while(my $line = <IN>){
		    chomp($line);
                    my @a = split(/\t/,$line);
                    my $gene = $a[0];
                    $HIGH_GA{$gene} = 1;
                }
                close(IN);
            }
        }
    }
}

if (($type =~ /^exon/i) || ($type =~ /^intron/i) || ($type =~ /^intergenic/i)){
    open(OUTFILE, ">$out");
    print OUTFILE "id";
    for(my $i=0; $i<@ID; $i++) {
	print OUTFILE "\t$ID[$i]";
    }
    if ($type =~ /^exon/i){
	if ($novel eq "true"){
	    print OUTFILE "\tNovelExon";
	}
	if ($filter eq "true"){
	    print OUTFILE "\thighExp";
	}
    }
    if ($type =~ /^intron/i){
	if ($novel eq "true"){
	    print OUTFILE "\tNovelIntron";
	}
        if ($filter eq "true"){
            print OUTFILE "\thighExp";
        }
    }
    print OUTFILE "\n";
    for(my $i=0; $i<$rowcnt; $i++) {
	if ($type =~ /^exon/i){
	    print OUTFILE "exon:$id[$i]";
	}
	if ($type =~ /^intron/i){
	    if (exists $FR{$id[$i]}){
		print OUTFILE "flanking:$id[$i]";
	    }
	    else{
		print OUTFILE "intron:$id[$i]";
	    }
	}
	if ($type =~ /^intergenic/i){
	    print OUTFILE "$id[$i]";
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
	    if ($filter eq "true"){
		if (exists $HIGH_E{$id[$i]}){
		    print OUTFILE "\tH";
		}
		else{
		    print OUTFILE "\t.";
		}
	    }
	}
	if ($type =~ /^intron/i){
	    if ($novel eq "true"){
		if (exists $NOVEL_I{$id[$i]}){
		    print OUTFILE "\tN";
		}
		else{
		    print OUTFILE "\t.";
		}
	    }
	    if ($filter eq "true"){
		if (exists $HIGH_I{$id[$i]}){
		    print OUTFILE "\tH";
		}
		else{
		    print OUTFILE "\t.";
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
    print OUT_MIN "\tgeneCoordinate\tgeneSymbol";
    print OUT_MAX "\tgeneCoordinate\tgeneSymbol";
=comment
    if ($filter eq "true"){
	print OUT_MIN "\thighExp";
	print OUT_MAX "\thighExp";
    }
=cut
    print OUT_MIN "\n";
    print OUT_MAX "\n";
    for(my $i=0; $i<$rowcnt; $i++) {
	print OUT_MIN "$id[$i]";
	print OUT_MAX "$id[$i]";
        for(my $j=0; $j<$filecnt; $j++) {
            print OUT_MIN "\t$DATA_MIN[$j][$i]";
            print OUT_MAX "\t$DATA_MAX[$j][$i]";
	}
	print OUT_MIN "\t$coord[$i]\t$sym[$i]";
	print OUT_MAX "\t$coord[$i]\t$sym[$i]";
=comment
	if ($filter eq "true"){
	    if (exists $HIGH_G{$id[$i]}){
		print OUT_MIN "\tH";
		print OUT_MAX "\tH";
	    }
	    else{
		print OUT_MIN "\t.";
		print OUT_MAX "\t.";
	    }
	}
=cut
	print OUT_MIN "\n";
	print OUT_MAX "\n";
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
	    if ($line =~ /^ensGeneID/){
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
	$id =~ s/.intronmappers.norm.intronquants//;
	$id =~ s/.exonmappers.norm.exonquants//;
	$id =~ s/.exonmappers.norm_u.sense.exonquants//;
	$id =~ s/.exonmappers.norm_nu.sense.exonquants//;
	$id =~ s/.intronmappers.norm_u.sense.intronquants//;
	$id =~ s/.intronmappers.norm_nu.sense.intronquants//;
	$id =~ s/.gene.norm_nu.genefilter.antisense.genequants//;
	$id =~ s/.gene.norm_u.genefilter.antisense.genequants//;
	$id =~ s/.gene.norm.genequants//;
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
		if ($line =~ /^ensGeneID/){
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
	    if ($filter eq "true"){
		print OUTFILE "\thighExp";
	    }

	}
	if ($type =~ /^intron/i){
	    if ($novel eq "true"){
		print OUTFILE "\tNovelIntron";
	    }
            if ($filter eq "true"){
                print OUTFILE "\thighExp";
            }
	}
	print OUTFILE "\n";
	for(my $i=0; $i<$rowcnt; $i++) {
	    if ($type =~ /^exon/i){
		print OUTFILE "exon:$id[$i]";
	    }
	    if ($type =~ /^intron/i){
		if (exists $FR{$id[$i]}){
		    print OUTFILE "flanking:$id[$i]";
		}
		else{
		    print OUTFILE "intron:$id[$i]";
		}
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
		if ($filter eq "true"){
		    if (exists $HIGH_EA{$id[$i]}){
			print OUTFILE "\tH";
		    }
		    else{
			print OUTFILE "\t.";
		    }
		}
	    }
	    if ($type =~ /^intron/i){
		if (exists $FR{$id[$i]}){
		    print OUTFILE "\tF";
		}
		else{
		    if ($novel eq "true"){
			if (exists $NOVEL_I{$id[$i]}){
			    print OUTFILE "\tN";
			}
			else{
			    print OUTFILE "\t.";
			}
		    }
		    if ($filter eq "true"){
			if (exists $HIGH_IA{$id[$i]}){
			    print OUTFILE "\tH";
			}
			else{
			    print OUTFILE "\t.";
			}
		    }
		}
	    }
	    print OUTFILE "\n";
	}
    }
    if ($type =~ /^gene/i){
	open(OUT_MIN, ">$out_min_a");
	open(OUT_MAX, ">$out_max_a");
	print OUT_MIN "id";
	print OUT_MAX "id";
	for(my $i=0; $i<@ID; $i++) {
	    print OUT_MIN "\t$ID[$i]";
	    print OUT_MAX "\t$ID[$i]";
	}
	print OUT_MIN "\tgeneCoordinate\tgeneSymbol";
	print OUT_MAX "\tgeneCoordinate\tgeneSymbol";
=comment
	if ($filter eq "true"){
	    print OUT_MIN "\thighExp";
	    print OUT_MAX "\thighExp";
	}
=cut
	print OUT_MIN "\n";
	print OUT_MAX "\n";
	for(my $i=0; $i<$rowcnt; $i++) {
	    print OUT_MIN "$id[$i]";
	    print OUT_MAX "$id[$i]";
	    for(my $j=0; $j<$filecnt; $j++) {
		print OUT_MIN "\t$DATA_MIN[$j][$i]";
		print OUT_MAX "\t$DATA_MAX[$j][$i]";
	    }
	    print OUT_MIN "\t$coord[$i]\t$sym[$i]";
	    print OUT_MAX "\t$coord[$i]\t$sym[$i]";
=comment
	    if ($filter eq "true"){
		if (exists $HIGH_GA{$id[$i]}){
		    print OUT_MIN "\tH";
		    print OUT_MAX "\tH";
		}
		else{
		    print OUT_MIN "\t.";
		    print OUT_MAX "\t.";
		}
	    }
=cut
	    print OUT_MIN "\n";
	    print OUT_MAX "\n";
	}
    }
    close(OUT_MIN);
    close(OUT_MAX);
}
close(OUTFILE);
print "got here\n";
