#!/usr/bin/env perl
use strict;
use warnings;


my $USAGE= "Usage: perl cleanup.pl <sample dirs> <loc> [options]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

option: 
 -normdir <s>

 -fa : set this if the unaligned files are in fasta format

 -fq : set this if the unaligned files are in fastq format

 -gz : set this if the unaligned files are compressed

";
if(@ARGV<2) {
    die $USAGE;
}

my $cnt = 0;
my $gz = "false";
my $delete_temp_fa = "false";
my $bam = "false";
my $normdir = "";
my $ncnt = 0;
for(my $i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-gz'){
	$option_found = "true";
	$gz = "true";
    }
    if ($ARGV[$i] eq '-normdir'){
        $option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if ($ARGV[$i] eq '-fa'){
	$option_found = "true";
	$cnt++;
    }
    if ($ARGV[$i] eq '-fq'){
	$option_found = "true";
	$delete_temp_fa = "true";
	$cnt++;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if ($cnt ne '1'){
    die "please specify the type of the unaligned files : '-fa' or '-fq'\n";
}
if ($ncnt ne '1'){
    die "please specify -normdir path\n";
}
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $norm_dir = "$normdir/EXON_INTRON_JUNCTION/";
my $exon_dir = $norm_dir . "/FINAL_SAM/exonmappers";
my $intron_dir = $norm_dir . "/FINAL_SAM/intronmappers";
my $ig_dir = $norm_dir . "/FINAL_SAM/intergenicmappers";
my $spread_dir = $norm_dir . "/SPREADSHEETS";
my $gnorm_dir = "$normdir/GENE/";
my $gene_dir = $gnorm_dir . "/FINAL_SAM/";
my $gspread_dir = $gnorm_dir . "/SPREADSHEETS";
my @g;

if (-e "$LOC/one-line.fa"){
    `rm $LOC/one-line.fa`;
}

if (-e "$ARGV[0].resume"){
    `rm $ARGV[0].resume`;
}

if ($delete_temp_fa eq "true"){
    if ($gz eq "true"){
	@g = glob("$LOC/*/*fa.gz");
	if (@g > 0){
	    `rm $LOC/*/*.fa.gz`;
	}
    }
    else{
	@g = glob("$LOC/*/*.fa");
	if (@g > 0){
	    `rm $LOC/*/*.fa`;
	}
    }
}

if (-d $gene_dir){
    @g = glob("$gene_dir/*gene.norm.txt");
    if (@g > 0){
	`rm $gene_dir/*gene.norm.txt`;
    }
    @g = glob("$gene_dir/*gene.norm.txt.gz");
    if (@g > 0){
	`rm $gene_dir/*gene.norm.txt.gz`;
    }
    @g = glob("$gene_dir/*gene.norm.genes.txt");
    if (@g > 0){
	`rm $gene_dir/*gene.norm.genes.txt`;
    }
    @g = glob("$gene_dir/*/*gene.norm.txt");
    if (@g > 0){
	`rm $gene_dir/*/*gene.norm.txt`;
    }
    @g = glob("$gene_dir/*/*gene.norm.txt.gz");
    if (@g > 0){
	`rm $gene_dir/*/*gene.norm.txt.gz`;
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
=comment
if (-d $gspread_dir){
    @g = glob("$gspread_dir/master_list_of_gene_counts_*.txt");
    if (@g > 0){
	`rm $gspread_dir/master_list_of_gene_counts_*.txt`;
    }
}
=cut
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
=comment
    @g = glob("$spread_dir/master_list_of_*_counts_*.txt");
    if (@g > 0){
        `rm $spread_dir/master_list_of_*_counts_*.txt`;
    }
=cut
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
    @g = glob("$LOC/$line/blastdb*blastout*");
    if (@g > 0){
	`rm $LOC/$line/blastdb*blastout*`;
    }
    @g = glob("$LOC/$line/blastdb*$line*.nhr");
    if (@g>0){
	`rm $LOC/$line/blastdb*$line*.nhr`;
    }
    @g = glob("$LOC/$line/blastdb*$line*.nin");
    if (@g>0){
	`rm $LOC/$line/blastdb*$line*.nin`;
    }
    @g = glob("$LOC/$line/blastdb*$line*.nsq");
    if (@g>0){
	`rm $LOC/$line/blastdb*$line*.nsq`;
    }
    @g = glob("$LOC/$line/blastdb*$line.nal");
    if (@g>0){
	`rm $LOC/$line/blastdb*$line.nal`;
    }
    @g = glob("$LOC/$line/*_junctions_all.sorted.rum");
    if (@g>0){
	`rm $LOC/$line/*junctions_*`;
    }
    #rm tempheader
    @g = glob("$LOC/$line/tempheader*");
    if (@g>0){
	`rm $LOC/$line/tempheader`;
    }
    #rm temp query files
    @g = glob("$LOC/$line/query.temp.*");
    if (@g>0){
	`rm $LOC/$line/query.temp.*`;
    }
}
print "got here\n";
