#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl get_master_list_of_intergenic_regions.pl <gene info file> <loc> [option]

<gene info file> gene info file must contain columns with the following suffixes: chrom, strand, txStart, and txEnd.
<loc> is where the sample directories are

options:
 -stranded: set this if your data are strand-specific.
 -FR <n> : by default, 5000 bases up/downstream of each gene 
           will be considered flanking regions. 
           use this option to change the size <n>. 
 -readlength <n> : by default, 100bp will be used as readlength.
                   use this option to change the readlength <n>.

";

if (@ARGV <2 ){
    die $USAGE;
}

my $FR = 5000;
my $stranded = "false";
my $readlength = 100;
for(my$i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq "-FR"){
	$option_found = "true";
	$FR = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-readlength'){
	$option_found = "true";
	$readlength = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}


my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my $geneinfoFile = $ARGV[0];
my (%IG, %GENESTART);
open(GENE, $geneinfoFile) or die "cannot find file \"$geneinfoFile\"\n";
my $header = <GENE>;
chomp($header);
my @GHEADER = split(/\t/, $header);
my ($chrcol, $txstartcol, $txendcol, $strandcol);
for(my $i=0; $i<@GHEADER; $i++){
    if ($GHEADER[$i] =~ /chrom$/){
        $chrcol = $i;
    }
    if ($GHEADER[$i] =~ /strand$/){
        $strandcol = $i;
    }
    if ($GHEADER[$i] =~ /txStart$/){
        $txstartcol = $i;
    }
    if ($GHEADER[$i] =~ /txEnd$/){
        $txendcol = $i;
    }
}

if (!defined($chrcol) || !defined($txstartcol) || !defined($txendcol) || !defined($strandcol)){
    die "Your header must contain columns with the following suffixes: chrom, strand, txStart and txEnd\n";
}

my %TX_tmp;
while(my $line = <GENE>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $chr = $a[$chrcol];
    my $txSt = $a[$txstartcol];
    my $txEnd = $a[$txendcol];
    my $str = $a[$strandcol];
    $txSt++;#to 1-based coord
    my $tx = "$chr:$txSt-$txEnd";
    push(@{$TX_tmp{$tx}},$str);
}
close(GENE);

my %TX;
my %BOTH;
my $tempfile = "$LOC/temp_tx.txt";
my $readlength_2 = int($readlength/2);
open(TEMP, ">$tempfile");
foreach my $tx (sort {cmpChrs($a,$b)} keys %TX_tmp) {
    my @unique = &uniq(@{$TX_tmp{$tx}});
    my $size = @unique;
    if ($size == 1){
	print TEMP "$tx\n";
	$TX{$tx} = $unique[0];
    }
    else{
	print TEMP "$tx\n";
	$TX{$tx} = $unique[0];
	$BOTH{$tx} = 1;

	my $tmptx = "$tx.1";
	$TX{$tmptx} = $unique[1];
    }
}
close(TEMP);

my %INF_INTRON;

open(TEMP, $tempfile) or die "cannot find '$tempfile\n'";
my $firstcoord = <TEMP>;
chomp($firstcoord);
(my $chr, my $start, my $end) = $firstcoord =~  /^(.*):(\d*)-(\d*)$/g;
my ($interg_end, $intron, $interg, $intron_end, $intron_start, $interg_start);
if ($start > 1){
    if ($start >= $readlength_2){
	#1 to first tx start - FR : IG
	$intron_end = $start - 1;
	if ($intron_end > $FR){
	    $interg_end = $intron_end - $FR; 
	    $interg = "$chr:1-$interg_end";
	    $IG{$interg} = 1;
	    # ig_end+1 to start : INF_INTRON
	    my $intron_start = $interg_end + 1;
	    $intron = "$chr:$intron_start-$intron_end";
	}
	else{ # if 1 to first tx start is <= $FR
	    $intron = "$chr:1-$intron_end";
	}
	$INF_INTRON{$intron} = $TX{$firstcoord};
	#print "$firstcoord\ninterg:$interg\nintron:$intron\t$TX{$firstcoord}\n";#debug
	if ($stranded eq "true"){
	    if (exists $BOTH{$firstcoord}){
		my $tmpfirstcoord = $firstcoord . ".1";
		$intron = $intron . ".1";
		$INF_INTRON{$intron} = $TX{$tmpfirstcoord};
		#print "$tmpfirstcoord\ninterg:$interg\nintron:$intron\t$TX{$tmpfirstcoord}\n";#debug
	    }
	}
    }
    else{
	$interg_end = $start - 1;
	$interg = "$chr:1-$interg_end";
	$IG{$interg} = 1;
	#print "$firstcoord\ninterg:$interg\n";#debug
    }
}
#print "\n====\n";#debug

while(my $coord = <TEMP>){
    chomp($coord);
    (my $tx_chr, my $tx_start, my $tx_end) = $coord =~  /^(.*):(\d*)-(\d*)$/g;
    #print "\$chr:\$start-\$end:$chr:$start-$end\n"; #debug
    #print "\$tx_chr:\$tx_start-\$tx_end:$tx_chr:$tx_start-$tx_end\n"; #debug
    if ($chr eq $tx_chr){
        my $overlap = $tx_start - $end;
        # does not overlap
        if ($overlap > 1){
	    if ($overlap >= $readlength_2){
		my $FR_2 = $FR * 2;
		if ($overlap > $FR_2){
		    my $int_start_1 = $end + 1;
		    my $int_end_2 = $tx_start - 1;
		    
		    my $int_end_1 = $end + $FR;
		    $interg_start = $int_end_1 + 1;
		    $interg_end = $int_end_2 - $FR;
		    my $int_start_2 = $interg_end + 1;
		    
		    my $intron1 = "$chr:$int_start_1-$int_end_1";
		    $interg = "$chr:$interg_start-$interg_end";
		    my $intron2 = "$chr:$int_start_2-$int_end_2";
		    my $prev_coord = "$chr:$start-$end";
		    #print "$intron1:$TX{$prev_coord}\n";#debug
		    #print "$interg\n";#debug
		    #print "$intron2:$TX{$coord}\n";#debug

		    $INF_INTRON{$intron1} = $TX{$prev_coord};
		    $IG{$interg} = 1;
		    $INF_INTRON{$intron2} = $TX{$coord};
		    if ($stranded eq "true"){
			my $tx1 = "$chr:$start-$end";
			my $tx2 = "$coord";
			if (exists $BOTH{$tx1}){
			    my $tmp1 = $tx1 . ".1";
			    $intron1 = $intron1 . ".1";
			    $INF_INTRON{$intron1} = $TX{$tmp1};
			    #print "str---$intron1\t$TX{$tmp1}\n";#debug
			}
			if (exists $BOTH{$tx2}){
			    my $tmp2 = $tx2 . ".1";
			    $intron2 = $intron2 . ".1";
			    $INF_INTRON{$intron2} = $TX{$tmp2};
			    #print "str---$intron2\t$TX{$tmp2}\n";#debug
			}
		    }
		}
		else{
		    if ($overlap <= $readlength){
			my $int_start = $end + 1;
			my $int_end = $tx_start - 1;
			$intron = "$chr:$int_start-$int_end";
			my $tx1 = "$chr:$start-$end";
			my $tx2 = "$coord";
			$INF_INTRON{$intron} = $TX{$tx1};
			#print "$intron\t$TX{$tx1}\n";#debug
			if ($stranded eq "true"){
			    if ($TX{$tx1} ne $TX{$tx2}){
				$intron = $intron . ".1";
				$INF_INTRON{$intron} = $TX{$tx2};
				#print "str---$intron\t$TX{$tx2}\n";#debug
			    }
			}
		    }
		    else{
			my $size = int($overlap/2);
			$size--;
			my $int_start_1 = $end + 1;
			my $int_end_2 = $tx_start - 1;
			
			my $int_end_1 = $int_start_1 + $size;
			my $int_start_2 = $int_end_1 + 1;
		    
			my $intron1 = "$chr:$int_start_1-$int_end_1";
			my $intron2 = "$chr:$int_start_2-$int_end_2";
			my $prev_coord = "$chr:$start-$end";
			$INF_INTRON{$intron1} = $TX{$prev_coord};
			$INF_INTRON{$intron2} = $TX{$coord};
		    
			#print "overlap:$overlap\n";#debug
			#print "size:$size\n";#debug
			#print "$intron1\t$TX{$prev_coord}\n";#debug
			#print "$intron2\t$TX{$coord}\n";#debug

			if ($stranded eq "true"){
			    my $tx1 = "$chr:$start-$end";
			    my $tx2 = "$coord";
			    if (exists $BOTH{$tx1}){
				my $tmp1 = $tx1 . ".1";
				$intron1 = $intron1 . ".1";
				$INF_INTRON{$intron1} = $TX{$tmp1};
				#print "str---$intron1\t$TX{$tmp1}\n";#debug
			    }
			    if (exists $BOTH{$tx2}){
				my $tmp2 = $tx2 . ".1";
				$intron2 = $intron2 . ".1";
				$INF_INTRON{$intron2} = $TX{$tmp2};
				#print "str---$intron2\t$TX{$tmp2}\n";#debug
			    }
			}
		    }
		}
	    }
=comment # gap < readlength/2: ignore or consider intergenic?
	    else{
		$interg_start = $end + 1;
		$interg_end = $tx_start - 1;
		$interg = "$chr:$interg_start-$interg_end";
		$IG{$interg} = 1;
		print "GAP<READLENGTH/2\tinterg:$interg\n";#debug
	    }
=cut
	    $start = $tx_start;
            $end = $tx_end;
	}
        else{
	    if ($tx_end > $end){
		$start = $tx_start;
		$end = $tx_end;
	    }
        }
    }
    else{
        # current chr: last end to the end of chrom
	$intron_start = $end + 1;
	$intron_end = $intron_start + $FR - 1;
	
        $interg_start = $intron_end + 1;
        $interg_end = $interg_start * 2;
	my $prev_coord = "$chr:$start-$end";
	$intron = "$chr:$intron_start-$intron_end";
	$INF_INTRON{$intron} = $TX{$prev_coord};
        $interg = "$chr:$interg_start-$interg_end";
        $IG{$interg} = 1;
	#print "LASTOFCHR:$prev_coord\ninterg:$interg\nintron:$intron\t$TX{$prev_coord}\n";#debug
	if ($stranded eq "true"){
	    if (exists $BOTH{$prev_coord}){
		my $tmptx2 = $prev_coord . ".1";
		my $intron = $intron . ".1";
		$INF_INTRON{$intron} = $TX{$tmptx2};
		#print "str---$intron:$TX{$tmptx2}\n";#debug
	    }
	}
        # next chr: 0 to first gene
	#print "start:$tx_start\treadlength_2:$readlength_2\n";
	if ($tx_start > 1){
	    if ($tx_start >= $readlength_2){
		$intron_end = $tx_start - 1;
		if ($intron_end > $FR){
		    $interg_end = $intron_end - $FR;
		    $interg = "$tx_chr:1-$interg_end";
		    $IG{$interg} = 1;
		    # interg_end+1 to start : INF_INTRON
		    $intron_start = $interg_end + 1;
		    $intron = "$tx_chr:$intron_start-$intron_end";
		    #print "FIRSTOFNEWCHR:$coord\ninterg:$interg\nintron:$intron\t$TX{$coord}\n";#debug
		}
		else{ # if 0 to first tx start is <= $FR
		    $intron = "$tx_chr:1-$intron_end";
		    #print "FIRSTOFNEWCHR:$coord\nintron:$intron\t$TX{$coord}\n";#debug
		}
		$INF_INTRON{$intron} = $TX{$coord};
		if ($stranded eq "true"){
		    if (exists $BOTH{$coord}){
			my $tmp = $coord . ".1";
			$intron = $intron . ".1";
			$INF_INTRON{$intron} = $TX{$tmp};
			#print "str---intron:$intron\t$TX{$tmp}\n";#debug
		    }
		}
	    }
	    else{
		$interg_end = $tx_start - 1;
		$interg = "$tx_chr:1-$interg_end";
		$IG{$interg} = 1;
		#print "$coord\ninterg:$interg\n";#debug
	    }
	}
	$start = $tx_start;
	$end = $tx_end;
    }
    $chr = $tx_chr;
    #print "\n========\n";#debug
}
close(TEMP);

# last gene to max
$intron_start = $end + 1;
$intron_end = $intron_start + $FR - 1;
$interg_start = $intron_end + 1;
$interg_end = $interg_start * 2;
$intron = "$chr:$intron_start-$intron_end";
my $prev_coord = "$chr:$start-$end";
$INF_INTRON{$intron}=$TX{$prev_coord};
$interg = "$chr:$interg_start-$interg_end";
$IG{$interg} = 1;
#print "LAST:$prev_coord\nintron:$intron\t$TX{$prev_coord}\ninterg:$interg\n";#debug
if ($stranded eq "true"){
    if (exists $BOTH{$prev_coord}){
	my $tmptx = $prev_coord . ".1";
	my $intron = $intron . ".1";
	$INF_INTRON{$intron} = $TX{$tmptx};
	#print "str---$intron:$TX{$tmptx}\n";#debug
    }
}

my $master_list_of_interg = "$LOC/master_list_of_intergenic_regions.txt";
open(MAS, ">$master_list_of_interg");
foreach my $interg (sort {cmpChrs($a,$b)} keys %IG) {
    print MAS "$interg\n";
}
close(MAS);

my $flanking_regions = "$LOC/list_of_flanking_regions.txt";
open(FR, ">$flanking_regions");
foreach my $int (sort {cmpChrs($a,$b)} keys %INF_INTRON){
    print FR "$int\t";
    if ($stranded eq "true"){
	print FR "$INF_INTRON{$int}";
    }
    print FR "\n";
}
close(FR);

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

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
