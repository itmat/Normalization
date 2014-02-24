if(@ARGV<2) {
    die "usage: annotate.pl <annotation file> <features file>

the <annotation file> should be downloaded from UCSC known-gene track including
at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the Linked Tables table.

the <features file> should have features formatted as either:
chr:start-end
where start and end are positive integers
chr is the name of the chromosome (or contig), names cannot have colon, semi-colon, comma or whitespace.

";
}

$annotation_file = $ARGV[0];
$features_file = $ARGV[1];

$onecol = $false;
$outputname = $false;
for($i=2; $i<@ARGV; $i++) {
    if($ARGV[$i] eq '-onecol') {
	$onecol = "true";
    }
    if($ARGV[$i] eq '-outputname') {
	$outputname = "true";
    }
}

open(INFILE, $annotation_file);
$line = <INFILE>;
chomp($line);
@ANNOTHEADER = split(/\t/,$line);

for($i=0; $i<@ANNOTHEADER; $i++) {
    if($ANNOTHEADER[$i] =~ /.exonStarts$/) {
	$exonstartscol = $i;
    }
    if($ANNOTHEADER[$i] =~ /.exonEnds$/) {
	$exonendscol = $i;
    }
    if($ANNOTHEADER[$i] =~ /description$/) {
	$descriptioncol = $i;
    }
    if($ANNOTHEADER[$i] =~ /.name$/) {
	$namecol = $i;
    }
    if($ANNOTHEADER[$i] =~ /.chrom$/) {
	$chromcol = $i;
    }
    if($ANNOTHEADER[$i] =~ /geneSymbol$/) {
	$genesymbolcol = $i;
    }
}

while($line = <INFILE>) {
    chomp($line);
    @a = split(/\t/,$line);
    $a[$exonstartscol] =~ s/,$//;
    $a[$exonstartscol] =~ s/^,//;
    @S = split(/,/,$a[$exonstartscol]);
    $a[$exonendscol] =~ s/,$//;
    $a[$exonendscol] =~ s/^,//;
    @E = split(/,/,$a[$exonendscol]);
    for($i=0; $i<@S; $i++) {
	$start0 = $S[$i] + 1;
	$end0 = $E[$i];
	for($i1=0; $i1<2; $i1++) {
	    for($i2=0; $i2<2; $i2++) {
		$start = $start0 + $i1;
		$end = $end0 + $i2;
		$chr = $a[$chromcol];
		$exon = $chr . ":" . $start . "-" . $end;
		$exon_s = $chr . ":" . $start;
		$exon_e = $chr . ":" . $end;
		if(defined $EXONS{$exon}) {
		    next;
		}
		$EXONS{$exon} = 1;
		$DESC{$exon} = $a[$descriptioncol];
		$DESC{$exon} =~ s/;+$//;
		$DESC{$exon} =~ s/,+$//;
		$DESC{$exon} =~ s/:+$//;
		$NAME{$exon} = $a[$namecol];
		$SYMBOL{$exon} = $a[$genesymbolcol];
		$DESC{$exon_s} = $a[$descriptioncol];
		$NAME{$exon_s} = $a[$namecol];
		$SYMBOL{$exon_s} = $a[$genesymbolcol];
		$DESC{$exon_e} = $a[$descriptioncol];
		$NAME{$exon_e} = $a[$namecol];
		$SYMBOL{$exon_e} = $a[$genesymbolcol];
		$start_block = int($start / 1000);
		$end_block = int($end / 1000);
		for($j=$start_block; $j<=$end_block; $j++) {
		    push(@{$feature_overlaps_block{$chr}{$j}},$exon);  # all exons that overlap the ith span of 1K bases
		}
	    }
	}
    }
    for($i=0; $i<@S-1; $i++) {
	$start0 = $E[$i]+1;
	$end0 = $S[$i+1];
	for($i1=0; $i1<2; $i1++) {
	    for($i2=0; $i2<2; $i2++) {
		$start = $start0 + $i1;
		$end = $end0 + $i2;
		$chr = $a[$chromcol];
		$intron = $chr . ":" . $start . "-" . $end;
		$intron_s = $chr . ":" . $start;
		$intron_e = $chr . ":" . $end;
		if(defined $INTRONS{$intron}) {
		    next;
		}
		$INTRONS{$intron}=1;
		$DESC{$intron} = $a[$descriptioncol];
		$DESC{$intron} =~ s/;+$//;
		$DESC{$intron} =~ s/,+$//;
		$DESC{$intron} =~ s/:+$//;
		$NAME{$intron} = $a[$namecol];
		$SYMBOL{$intron} = $a[$genesymbolcol];
		$DESC{$intron_s} = $a[$descriptioncol];
		$NAME{$intron_s} = $a[$namecol];
		$SYMBOL{$intron_s} = $a[$genesymbolcol];
		$DESC{$intron_e} = $a[$descriptioncol];
		$NAME{$intron_e} = $a[$namecol];
		$SYMBOL{$intron_e} = $a[$genesymbolcol];
		$start_block = int($start / 1000);
		$end_block = int($end / 1000);
		for($j=$start_block; $j<=$end_block; $j++) {
		    push(@{$feature_overlaps_block{$chr}{$j}},$intron);  # all introns that overlap the ith span of 1K bases
		}
	    }
	}
    }
}
close(INFILE);

open(INFILE, $features_file);
while($line = <INFILE>) {
    chomp($line);
    if(!($line =~ /[^\s:,;]+:\d+-\d+/)) {
	print "$line\n";
	next;
    }
    $line =~ /([^\s:,;]+:\d+-\d+)/;
    $feature = $1;
    $feature_s = $feature;
    $feature_s =~ s/:\d+-/:/;
    $feature_e = $feature;
    $feature_e =~ s/-\d+$//;
    if($onecol eq 'true') {
	$delim = " : ";
    } else {
	$delim = "\t";
    }
    print "exon:$line\t";
    if($FEATURES{$feature}==1) {
	$thing = $feature;
    } elsif(defined $DESC{$feature_s}) {
	$thing = $feature_s;
    } elsif(defined $DESC{$feature_e}) {
	$thing = $feature_e;
    } else {
	$feature =~ /(.*):(\d+)-(\d+)$/;
	$feature_chr = $1;
	$feature_s = $2;
	$feature_e = $3;
	$start_block = int($feature_s / 1000);
	$end_block = int($feature_e / 1000);
	$min = 100000000;
	$flag = 0;
	for($j=$start_block; $j<=$end_block; $j++) {
	    $NN = @{$feature_overlaps_block{$feature_chr}{$j}};
	    for($k=0; $k<$NN; $k++) {
		$feature_o = $feature_overlaps_block{$feature_chr}{$j}[$k];
		$feature_o =~ /.*:(\d+)-(\d+)$/;
		$start_o = $1;
		$end_o = $2;
		if(abs($feature_s - $start_o) < $min) {
		    $annot_s = $SYMBOL{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_n = $NAME{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_d = $DESC{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $min = abs($feature_s - $start_o);
		    $flag = 1;
		}
		if(abs($feature_e - $start_o) < $min) {
		    $annot_s = $SYMBOL{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_n = $NAME{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_d = $DESC{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $min = abs($feature_e - $start_o);
		    $flag = 1;
		}
		if(abs($feature_s - $end_o) < $min) {
		    $annot_s = $SYMBOL{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_n = $NAME{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_d = $DESC{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $min = abs($feature_s - $end_o);
		    $flag = 1;
		}
		if(abs($feature_e - $end_o) < $min) {
		    $annot_s = $SYMBOL{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_n = $NAME{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $annot_d = $DESC{$feature_overlaps_block{$feature_chr}{$j}[$k]};
		    $min = abs($feature_e - $end_o);
		    $flag = 1;
		}
	    }
	}
	if($flag == 1 && $min <= 100000) {
	    print "$annot_s";
	    if($outputname eq 'true') {
		print "$delim$annot_n";
	    }
	    print "$delim$annot_d";
	}
	if($flag == 1 && $min > 100000) {
	    print "$annot_s";
	    if($outputname eq 'true') {
		print "$delim";
		print "$min bases from: ";
		print $annot_n;
	    }
	    print "$delim$annot_d";
	}
	print "\n";
	next;
    }
    print "$SYMBOL{$thing}";
    if($outputname eq 'true') {
	print "$delim$NAME{$thing}";
    }
    print "$delim$DESC{$thing}";
    print "\n";
}
