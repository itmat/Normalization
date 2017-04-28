#!usr/bin/perl
use strict;
use warnings;

my $Usage =  "perl convert_gtf_to_PORT_geneinfo.transcripts.pl <gtffile>

[option]
 -convert_chrom <chromtable> : use this option to convert chromosome names to match the chromosome names in fasta.
			       <chromtable> should be a text file with the following format:
    			       from_chromosome_name\tto_chromosome_name

			       <chromtable> can be downloaded from: https://github.com/dpryan79/ChromosomeMappings


# Accepts a GTF file and coverts it to the following format:
#chrom	strand	txStart	txEnd	exonCount	exonStarts	exonEnds	name(txID)	name2(geneID)	ensemblToGeneName.value(genesymbol)	geneSymbol(for featurelevel normalization)

# This script derives the transcript info from the \"exon\" lines in the gtf file
# and assumes the exons are listed in order numerically, as opposed to by plus-
# strand coordinates. PORT geneinfo format requires the exons coordinates to be listed in
# order by plus-strand coordinates, so this script will reverse the order of
# exons for all minus-strand transcripts.


";

if (@ARGV<1){
    die $Usage;
}

my $convert = "false";
my %CHR;
my $table = "";
for(my $i=1;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-convert_chrom'){
	$convert = "true";
	$table = $ARGV[$i+1];
	$i++;
	$option_found= "true";
    }
    if ($option_found eq "false"){
	die "option $ARGV[$i] not recognized\n";
    }
}
if ($convert eq "true"){
    open(IN, $table) or die "cannot open $table\n";
    while(my $line = <IN>){
	chomp($line);
	my @x = split(/\t/,$line);
	my $id = $x[0];
	my $to = $x[1];
	$CHR{$id} = $to;
    }
    close(IN);
}

my $gtf_file = $ARGV[0]; #Name of gtf file
my @sp = split("/",$gtf_file);
my $name = $sp[@sp-1];
$name =~ s/.gtf$//;
my $outfile = $gtf_file;
$outfile =~ s/.gtf$/.PORT_geneinfo.txt/;

open(OUT, ">$outfile") or die "cannot open $outfile\n";
print OUT "#$name.chrom\t$name.strand\t$name.txStart\t$name.txEnd\t$name.exonCount\t$name.exonStarts\t$name.exonEnds\t$name.name\t$name.name2\t$name.ensemblToGeneName.value\t$name.geneSymbol\t$name.biotype\n";

#my $line = ""; #Current line of input
my @line_data; #Array of line fields
my $curr_tx = ""; #transcript ID of current line from gtf being processed
my $tx_id = ""; #ID of current transcript
my $gene = ""; #gene ID of current transcript
my $genesym = ""; #gene symbol of current transcript
my $chr = ""; #Chromosome for current transcript
my $strand = ""; #Strand for current transcript
my @starts; #List of exon start coordinates for current transcript
my @stops; #List of exon stop coordinates for current transcript
my $ex_count = 1; #Number of exons in current transcript
my $biotype = "";

#count header lines
open(INFILE, $gtf_file) or die "Cannot open the file $gtf_file: $!";
my $cnt = 0;
my $line = <INFILE>;
my @a = split(/\t/,$line);
my $n = @a;

until($n > 1) {
    $line = <INFILE>;
    chomp($line);
    @a = split(/\t/,$line);
    $n = @a;
    $cnt++;
}
close(INFILE);
open(INFILE, $gtf_file) or die "Cannot open the file $gtf_file: $!";
for(my $i=0; $i<$cnt; $i++) { # skip header
    my $line = <INFILE>;
}
#Prime input variables for loop
$line = <INFILE>;
chomp($line);
@line_data = split('\t', $line); #Separate line by tabs
#Step through lines in GTF file until first exon entry found
while($line_data[2] ne "exon") {
    $line = <INFILE>;
    chomp($line);
    @line_data = split('\t', $line); #Separate line by tabs
}
#Extract transcript and gene IDs from first line
$line_data[8] =~ m/transcript_id "([^"]+)";/;
$tx_id = $1;
$line_data[8] =~ m/gene_id "([^"]+)";/;
$gene = $1;
$line_data[8] =~ m/gene_name "([^"]+)";/;
$genesym = $1;
if ($genesym =~ /^$/){
    $genesym = $gene;
}
$line_data[8] =~ m/gene_biotype "([^"]+)";/;
$biotype = $1;

#check transcript id and gene id.
if ($tx_id eq $gene){
    print "\n\nWARNING: transcript_id '$tx_id' and gene_id '$gene' are the same.\n\n";
}

#Load data from first transcript into appropriate variables
$chr = $line_data[0];
if ($convert eq "true"){
    if (exists $CHR{$chr}){
	$chr =~ s/$chr/$CHR{$chr}/;
    }
}
$strand = $line_data[6];
#Subtract 1 to convert from 1-based to zero-based half-open
#used by the RUM annotation.
@starts = ($line_data[3] - 1);
@stops = ($line_data[4]);

while($line = <INFILE>) {
    
    chomp($line);
    @line_data = split('\t', $line); #Separate line by tabs
    
    #Check if current line is of type "exon"
    if($line_data[2] eq "exon") {
        
        #Extract transcript and gene IDs from current line
        $line_data[8] =~ m/transcript_id "([^"]+)";/;
        $curr_tx = $1;

        #If the transcript in the current line is a new transcript
        if($curr_tx ne $tx_id) {
            
            #Check strand of transcript. If minus, reverse the order of the exons.
            if($strand eq "-") {
                @starts = reverse @starts;
                @stops = reverse @stops;
            }
            
            #Print data from previous transcript
            print OUT "$chr\t$strand\t$starts[0]\t$stops[-1]\t$ex_count\t";
            foreach my $coord (@starts) {
                print OUT "$coord,";
            }
            print OUT "\t";
            foreach my $coord (@stops) {
                print OUT "$coord,";
            }
            print OUT "\t$tx_id\t$gene\t$genesym\t$genesym\t$biotype\n";
            
            #Load data from new transcript into appropriate variables
            $tx_id = $curr_tx;
            $line_data[8] =~ m/gene_id "([^"]+)";/;
            $gene = $1;
	    $line_data[8] =~ m/gene_name "([^"]+)";/;
	    $genesym = $1;
            if ($genesym =~ /^$/){
                $genesym = $gene;
            }
            $chr = $line_data[0];
            $line_data[8] =~ m/gene_biotype "([^"]+)";/;
            $biotype = $1;
	    if ($convert eq "true"){
		if (exists $CHR{$chr}){
		    $chr =~ s/$chr/$CHR{$chr}/;
		}
	    }
            $strand = $line_data[6];
            @starts = ($line_data[3] - 1);
            @stops = ($line_data[4]);
            $ex_count = 1;
        }
        #Else, still processing the same transcript
        else {
            #Add current start and stop coordinates
            push(@starts, ($line_data[3] - 1));
            push(@stops, $line_data[4]);
            $ex_count++;
        }
    }
}

#Check strand of transcript. If minus, reverse the order of the exons.
if($strand eq "-") {
    @starts = reverse @starts;
    @stops = reverse @stops;
}

#Print data from final transcript
print OUT "$chr\t$strand\t$starts[0]\t$stops[-1]\t$ex_count\t";
foreach my $coord (@starts) {
    print OUT "$coord,";
}
print OUT "\t";
foreach my $coord (@stops) {
    print OUT "$coord,";
}
print OUT "\t$tx_id\t$gene\t$genesym\t$genesym\t$biotype\n";

close(INFILE);
