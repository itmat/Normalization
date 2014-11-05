#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl get_master_list_of_intergenic_regions.pl <gene info file> <loc> [option]

<gene info file> gene info file must contain columns with the following suffixes: chrom, txStart, and txEnd.
<loc> is where the sample directories are

";

if (@ARGV <2 ){
    die $USAGE;
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my $geneinfoFile = $ARGV[0];
my (%IG, %GENESTART);

open(GENE, $geneinfoFile) or die "cannot find file \"$geneinfoFile\"\n";
my $header = <GENE>;
chomp($header);
my @GHEADER = split(/\t/, $header);
my ($chrcol, $txstartcol, $txendcol);
for(my $i=0; $i<@GHEADER; $i++){
    if ($GHEADER[$i] =~ /.chrom$/){
        $chrcol = $i;
    }
    if ($GHEADER[$i] =~ /.txStart$/){
        $txstartcol = $i;
    }
    if ($GHEADER[$i] =~ /.txEnd$/){
        $txendcol = $i;
    }
}

if (!defined($chrcol) || !defined($txstartcol) || !defined($txendcol)){
    die "Your header must contain columns with the following suffixes: chrom, txStart and txEnd\n";
}

my %TX;
while(my $line = <GENE>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $chr = $a[$chrcol];
    my $txSt = $a[$txstartcol];
    my $txEnd = $a[$txendcol];
#    $txSt++;
    my $tx = "$chr:$txSt-$txEnd";
    $TX{$tx} = 1;
}
close(GENE);

my $tempfile = "$LOC/temp_tx.txt";
open(TEMP, ">$tempfile");
foreach my $tx (sort {cmpChrs($a,$b)} keys %TX) {
    print TEMP "$tx\n";
}
close(TEMP);


open(TEMP, $tempfile) or die "cannot find '$tempfile\n'";
my $firstcoord = <TEMP>;
(my $chr, my $start, my $end) = $firstcoord =~  /^(.*):(\d*)-(\d*)$/g;
# 0 to first gene
my $interg = "$chr:0-$start";
$IG{$interg} = 1;
while(my $coord = <TEMP>){
    chomp($coord);
    (my $tx_chr, my $tx_start, my $tx_end) = $coord =~  /^(.*):(\d*)-(\d*)$/g;    
#    print "\$chr:\$start-\$end:$chr:$start-$end\n"; #debug
#    print "\$tx_chr:\$tx_start-\$tx_end:$tx_chr:$tx_start-$tx_end\n"; #debug
    if ($chr eq $tx_chr){
	my $overlap = $tx_start - $end;
	# does not overlap
	if ($overlap > 0){
	    my $interg_start = $end+1;
	    my $interg_end = $tx_start;
	    my $interg = "$tx_chr:$interg_start-$interg_end";
	    $start = $tx_start;
	    $end = $tx_end;
	    $IG{$interg} = 1;
#	    print "$interg\n"; #debug
	}
	else{
	    my @starts = ($start, $tx_start);
	    my @ends = ($end, $tx_end);
	    $start = &get_min(@starts);
	    $end = &get_max(@ends);
	}
    }
    else{
	# last end to the end of chrom
	my $interg_start = $end + 1;
	my $interg_end = $interg_start * 2;
	my $interg_last = "$chr:$interg_start-$interg_end";
	$IG{$interg_last} = 1;
	# 0 to first gene
	my $interg_first = "$tx_chr:0-$tx_start";
	$IG{$interg_first} = 1;
	$start = $tx_start;
	$end = $tx_end;
    }
    $chr = $tx_chr;    
}
# last gene to max
my $interg_start = $end + 1;
my $interg_end = $interg_start + $interg_start * 2;
my $interg_last = "$chr:$interg_start-$interg_end";
$IG{$interg_last} = 1;
close(TEMP);

my $master_list_of_interg = "$LOC/master_list_of_intergenic_regions.txt";
open(MAS, ">$master_list_of_interg");
foreach my $interg (sort {cmpChrs($a,$b)} keys %IG) {
    print MAS "$interg\n";
}
close(MAS);
`rm $tempfile`;
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
            foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
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
                foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
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
