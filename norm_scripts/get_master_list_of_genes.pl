#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl get_master_list_of_genes.pl <ensGenes file> <loc> [option]

<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value
<loc> is where the sample directories are

option:
 -stranded: set this if your data are strand-specific.
 -percent <n> : by default, 0% of the size of first and last exon of each transcript 
                will be added to the start of the first and the end of the last exon, respectively.
                use this option to change the percentage <n>. (<n> has to be a number between 0-100)


";

if (@ARGV <2 ){
    die $USAGE;
}
my $percent = 0;
my $stranded = "false";
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq "-percent"){
        $option_found = "true";
        $percent = $ARGV[$i+1];
        $i++;
	if (($percent !~ /(\d+$)/) || ($percent > 100) || ($percent < 0) ){
            die "-percent <n> : <n> needs to be a number between 0-100\n";
        }
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}


my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my $ensFile = $ARGV[0];
my (%ID, %GENECHR, %GENEST, %GENEEND);
open(ENS, $ensFile) or die "cannot find file \"$ensFile\"\n";
my $header = <ENS>;
chomp($header);
my @ENSHEADER = split(/\t/, $header);
my ($genenamecol, $genesymbolcol, $txchrcol, $txstartcol, $txendcol, $strandcol, $exonStcol, $exonEndcol);
for(my $i=0; $i<@ENSHEADER; $i++){
    if ($ENSHEADER[$i] =~ /name2$/){
        $genenamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /strand$/){
        $strandcol = $i;
    }
    if ($ENSHEADER[$i] =~ /ensemblToGeneName.value$/){
        $genesymbolcol = $i;
    }
    if ($ENSHEADER[$i] =~ /chrom/){
        $txchrcol = $i;
    }
    if ($ENSHEADER[$i] =~ /txStart/){
        $txstartcol = $i;
    }
    if ($ENSHEADER[$i] =~ /txEnd/){
        $txendcol = $i;
    }
    if ($ENSHEADER[$i] =~ /exonStarts$/){
        $exonStcol = $i;
    }
    if ($ENSHEADER[$i] =~ /exonEnds$/){
        $exonEndcol = $i;
    }
}

if (!defined($genenamecol) || !defined($genesymbolcol) || !defined($txchrcol) || !defined($txstartcol)|| !defined($txendcol) || !defined($strandcol) || !defined($exonStcol) || !defined($exonEndcol)){
    die "Your header must contain columns with the following suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value\n";
}
my %STR;
while(my $line = <ENS>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $txchr = $a[$txchrcol];
    my $txst = $a[$txstartcol];
    my $txend = $a[$txendcol];
    my $exonStarts = $a[$exonStcol];
    my @s = split(",", $exonStarts);
    my $exonEnds = $a[$exonEndcol];
    my @e = split(",", $exonEnds);
    my $geneid = $a[$genenamecol];
    my $genesym = $a[$genesymbolcol];
    my $txstrand = $a[$strandcol];
    $txst = $txst - int(($e[0]-$s[0]) * $percent / 100);
    if ($txst < 0){
	$txst = 0;
    }
    $txend = $txend + int(($e[@s-1]-$s[@s-1]) * $percent / 100);
    $txst++;
    $ID{$geneid}= $genesym;
    $GENECHR{$geneid} = $txchr;
    push (@{$GENEST{$geneid}}, $txst);
    push (@{$GENEEND{$geneid}}, $txend);
    $STR{$geneid} = $txstrand;
}
close(ENS);

my %GENESORT;
foreach my $key (keys %ID){
    my $chr = $GENECHR{$key};
    my $min_st = &get_min(@{$GENEST{$key}});
    my $max_end = &get_max(@{$GENEEND{$key}});
    my $coord = "$chr:$min_st-$max_end";
    $GENESORT{$key} = $coord;
}
close(MAS);
my $master_list_of_genes = "$LOC/master_list_of_genes.txt";
open(MAS, ">$master_list_of_genes");

foreach my $key (sort {&cmpChrs($GENESORT{$a},$GENESORT{$b})} keys %GENESORT){
    my $coord = $GENESORT{$key};
    my $strand = $STR{$key};
    print MAS "$key\t$ID{$key}\t$coord\t";
    if ($stranded eq "true"){
	print MAS "$strand";
    }
    print MAS "\n";
}
close(MAS);

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

sub cmpChrs ($$) {
    my $a2_c = lc($_[1]);
    my $b2_c = lc($_[0]);
    if($a2_c eq 'finished1234') {
        return 1;
    }
    if($b2_c eq 'finished1234') {
        return -1;
    }
    if ($a2_c =~ /^\d+$/ && !($b2_c =~ /^\d+$/)) {
        return 1;
    }
    if ($b2_c =~ /^\d+$/ && !($a2_c =~ /^\d+$/)) {
        return -1;
    }
    if ($a2_c =~ /^[ivxym]+$/ && !($b2_c =~ /^[ivxym]+$/)) {
        return 1;
    }
    if ($b2_c =~ /^[ivxym]+$/ && !($a2_c =~ /^[ivxym]+$/)) {
        return -1;
    }
    if ($a2_c eq 'm' && ($b2_c eq 'y' || $b2_c eq 'x')) {
        return -1;
    }
    if ($b2_c eq 'm' && ($a2_c eq 'y' || $a2_c eq 'x')) {
        return 1;
    }
    if ($a2_c =~ /^[ivx]+$/ && $b2_c =~ /^[ivx]+$/) {
        $a2_c = "chr" . $a2_c;
        $b2_c = "chr" . $b2_c;
    }
    if ($a2_c =~ /$b2_c/) {
        return -1;
    }
    if ($b2_c =~ /$a2_c/) {
        return 1;
    }

    # dealing with roman numerals starts here
    if ($a2_c =~ /chr([ivx]+)/ && $b2_c =~ /chr([ivx]+)/) {
        $a2_c =~ /chr([ivx]+)/;
        my $a2_roman = $1;
        $b2_c =~ /chr([ivx]+)/;
        my $b2_roman = $1;
        my $a2_arabic = arabic($a2_roman);
        my $b2_arabic = arabic($b2_roman);
        if ($a2_arabic > $b2_arabic) {
            return -1;
        }
        if ($a2_arabic < $b2_arabic) {
            return 1;
        }
        if ($a2_arabic == $b2_arabic) {
            my $tempa = $a2_c;
            my $tempb = $b2_c;
            $tempa =~ s/chr([ivx]+)//;
            $tempb =~ s/chr([ivx]+)//;
            my %temphash;
            $temphash{$tempa}=1;
            $temphash{$tempb}=1;
            foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
                if ($tempkey eq $tempa) {
                    return 1;
                } else {
                    return -1;
                }
            }
        }
    }
    if ($b2_c =~ /chr([ivx]+)/ && !($a2_c =~ /chr([a-z]+)/) && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if ($a2_c =~ /chr([ivx]+)/ && !($b2_c =~ /chr([a-z]+)/) && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }

    if ($b2_c =~ /m$/ && $a2_c =~ /vi+/) {
        return 1;
    }
    if ($a2_c =~ /m$/ && $b2_c =~ /vi+/) {
        return -1;
    }

    # roman numerals ends here
    if ($a2_c =~ /chr(\d+)$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr(\d+)/) {
        my $numa = $1;
        if ($b2_c =~ /chr(\d+)/) {
            my $numb = $1;
            if ($numa < $numb) {
                return 1;
            }
            if ($numa > $numb) {
                return -1;
            }
            if ($numa == $numb) {
                my $tempa = $a2_c;
                my $tempb = $b2_c;
                $tempa =~ s/chr\d+//;
                $tempb =~ s/chr\d+//;
                my %temphash;
                $temphash{$tempa}=1;
                $temphash{$tempb}=1;
                foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
                    if ($tempkey eq $tempa) {
                        return 1;
                    } else {
                        return -1;
                    }
                }
            }
        } else {
            return 1;
        }
    }
    if ($a2_c =~ /chrx(.*)/ && ($b2_c =~ /chr(y|m)$1/)) {
        return 1;
    }
    if ($b2_c =~ /chrx(.*)/ && ($a2_c =~ /chr(y|m)$1/)) {
        return -1;
    }
    if ($a2_c =~ /chry(.*)/ && ($b2_c =~ /chrm$1/)) {
        return 1;
    }
    if ($b2_c =~ /chry(.*)/ && ($a2_c =~ /chrm$1/)) {
        return -1;
    }
    if ($a2_c =~ /chr\d/ && !($b2_c =~ /chr[^\d]/)) {
        return 1;
    }
    if ($b2_c =~ /chr\d/ && !($a2_c =~ /chr[^\d]/)) {
        return -1;
    }
    if ($a2_c =~ /chr[^xy\d]/ && (($b2_c =~ /chrx/) || ($b2_c =~ /chry/))) {
        return -1;
    }
    if ($b2_c =~ /chr[^xy\d]/ && (($a2_c =~ /chrx/) || ($a2_c =~ /chry/))) {
        return 1;
    }
    if ($a2_c =~ /chr(\d+)/ && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)/ && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])/ && !($b2_c =~ /chr(\d+)/) && !($b2_c =~ /chr[a-z]+/)) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])/ && !($a2_c =~ /chr(\d+)/) && !($a2_c =~ /chr[a-z]+/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z]+)/) {
        my $letter_a = $1;
        if ($b2_c =~ /chr([a-z]+)/) {
            my $letter_b = $1;
            if ($letter_a lt $letter_b) {
                return 1;
            }
            if ($letter_a gt $letter_b) {
                return -1;
            }
        } else {
            return -1;
        }
    }
    my $flag_c = 0;
    while ($flag_c == 0) {
	$flag_c = 1;
        if ($a2_c =~ /^([^\d]*)(\d+)/) {
            my $stem1_c = $1;
            my $num1_c = $2;
            if ($b2_c =~ /^([^\d]*)(\d+)/) {
                my $stem2_c = $1;
                my $num2_c = $2;
                if ($stem1_c eq $stem2_c && $num1_c < $num2_c) {
                    return 1;
                }
                if ($stem1_c eq $stem2_c && $num1_c > $num2_c) {
                    return -1;
                }
                if ($stem1_c eq $stem2_c && $num1_c == $num2_c) {
                    $a2_c =~ s/^$stem1_c$num1_c//;
                    $b2_c =~ s/^$stem2_c$num2_c//;
                    $flag_c = 0;
                }
            }
	}
    }
    if ($a2_c le $b2_c) {
	return 1;
    }
    if ($b2_c le $a2_c) {
	return -1;
    }
    return 1;
}
sub arabic($) {
    my $arg = shift;
    my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my  @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    isroman($arg) or return undef;
    my ($last_digit) = 1000;
    my $arabic=0;
    foreach (split(//, uc $arg)) {
	my ($digit) = $roman2arabic{$_};
	$arabic -= 2 * $last_digit if $last_digit < $digit;
	$arabic += ($last_digit = $digit);
    }
    $arabic;
}
sub isroman($) {
    my $arg = shift;
    return $arg ne '' and
	$arg =~ /^(?: M{0,3})
                 (?: D?C{0,3} | C[DM])
                 (?: L?X{0,3} | X[LC])
                 (?: V?I{0,3} | I[VX])$/ix;
}

