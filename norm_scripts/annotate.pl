use strict; 

if(@ARGV<3) { 
    die "usage: annotate.pl <annotation file> <features file> <outputfile> [option]

the <annotation file> should be downloaded from UCSC known-gene track including
at minimum the following suffixes: name (this should correspond to your main identifier, typically some kind of transcript id), chrom, exonStarts, exonEnds; and, optionally, the suffixes: geneSymbol, and description.

Each of the above suffixes should not appear in more than one column header.

the <features file> should have features formatted as:
chr:start-end
where start and end are positive integers
chr is the name of the chromosome (or contig), names cannot have colon, semi-colon, comma or whitespace.

option:
-onecol : set this if you want the annotation (transcript name, gene symbol, description) in one column delimted by ' ::: '
-outputdesc : set this if you don't want to output description. it will print the description by default.

";
}

my $annotation_file = $ARGV[0];
my $features_file = $ARGV[1];
my $output_file = $ARGV[2];

my $onecol = 'false'; 
my $outputdesc = 'true'; 
for(my $i=2; $i<@ARGV; $i++) {
  if($ARGV[$i] eq '-onecol') {
    $onecol = "true";
  }
  if($ARGV[$i] eq '-outputdesc') { 
    $outputdesc = "false";
  }
}

open(INFILE, $annotation_file) or die "file '$annotation_file' cannot open for reading.\n";
open(OUT, ">$output_file");
my $line = <INFILE>;
chomp($line);
my @ANNOTHEADER = split(/\t/,$line);

my ($exonstartscol, $exonendscol, $namecol, $descriptioncol, $genesymbolcol, $chromcol);

for(my $i=0; $i<@ANNOTHEADER; $i++) {
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

if (!defined($namecol) || !defined($chromcol) || !defined($exonstartscol) || !defined($exonendscol)) { 
  die "Your header must contain columns with the following suffixes: name, chrom, starts, ends\n";
}

my ($seen, $NAME, $SYMBOL, $DESC);
my $feature_overlaps_block;
while($line = <INFILE>) {
  chomp($line);
  my @a = split(/\t/, $line);
  $a[$exonstartscol] =~ s/,$//;
  $a[$exonstartscol] =~ s/^,//;
  my @S = split(/,/, $a[$exonstartscol]);
  $a[$exonendscol] =~ s/,$//;
  $a[$exonendscol] =~ s/^,//;
  my @E = split(/,/, $a[$exonendscol]);
  for(my $i=0; $i<@S; $i++) {
    my $start0 = $S[$i] + 1;
    my $end0 = $E[$i];
    my $chr = $a[$chromcol];
    my $base = $chr . ":" . $start0 . "-" . $end0;  
    for(my $i1=0; $i1<2; $i1++) {
      for(my $i2=0; $i2<2; $i2++) {
	my $start = $start0 + $i1;
	my $end = $end0 + $i2;
	my $exon = $chr . ":" . $start . "-" . $end;
	my $exonS = $chr . ":" . $start;
	my $exonE = $chr . ":" . $end;
	#exons can belong to multiple transcripts hence the below
	if ($seen->{$base}->{$a[$namecol]}) {
	  next;
	}
	if ($a[$namecol] =~ /\S/) {
	  $seen->{$base}->{$a[$namecol]} = 1;
	}
 	push(@{$NAME->{$exon}}, $a[$namecol]);
	push(@{$NAME->{$exonS}}, $a[$namecol]);
	push(@{$NAME->{$exonE}}, $a[$namecol]);

	if (defined $genesymbolcol) {
	  push(@{$SYMBOL->{$exon}}, $a[$genesymbolcol]);
	  push(@{$SYMBOL->{$exonS}}, $a[$genesymbolcol]);
	  push(@{$SYMBOL->{$exonE}}, $a[$genesymbolcol]);
	}
	if (defined $descriptioncol) {
	  $a[$descriptioncol] =~ s/;+$//;
	  $a[$descriptioncol] =~ s/,+$//;
	  $a[$descriptioncol] =~ s/:+$//;
	  push(@{$DESC->{$exon}}, $a[$descriptioncol]);
	  push(@{$DESC->{$exonS}}, $a[$descriptioncol]);
	  push(@{$DESC->{$exonE}}, $a[$descriptioncol]);
	}

	my $start_block = int($start / 1000);
	my $end_block = int($end / 1000);
	for(my $j=$start_block; $j<=$end_block; $j++) {
	  push(@{$feature_overlaps_block->{$chr}->{$j}},$exon);  # all exons that overlap the jth span of 1K bases
	}
      }
    }
  }
  for(my $i=0; $i<@S-1; $i++) {
    my $start0 = $E[$i]+1;
    my $end0 = $S[$i+1];
    my $chr = $a[$chromcol];
    my $base = $chr . ":" . $start0 . "-" . $end0; 
    for(my $i1=0; $i1<2; $i1++) {
      for(my $i2=0; $i2<2; $i2++) {
	my $start = $start0 + $i1;
	my $end = $end0 + $i2;
	my $intron = $chr . ":" . $start . "-" . $end;
	my $intronS = $chr . ":" . $start;
	my $intronE = $chr . ":" . $end;
	# introns can belong to multiple transcripts hence the below
	if ($seen->{$base}->{$a[$namecol]}) {
	  next;
	}
	if ($a[$namecol] =~ /^\S/) {
	  $seen->{$base}->{$a[$namecol]} = 1;
	}
	push(@{$NAME->{$intron}}, $a[$namecol]);
	push(@{$NAME->{$intronS}}, $a[$namecol]);
	push(@{$NAME->{$intronE}}, $a[$namecol]);

	if (defined $genesymbolcol) {
	  push(@{$SYMBOL->{$intron}}, $a[$genesymbolcol]);
	  push(@{$SYMBOL->{$intronS}}, $a[$genesymbolcol]);
	  push(@{$SYMBOL->{$intronE}}, $a[$genesymbolcol]);
	}
	if (defined $descriptioncol) {
	  $a[$descriptioncol] =~ s/;+$//;
	  $a[$descriptioncol] =~ s/,+$//;
	  $a[$descriptioncol] =~ s/:+$//;
	  push(@{$DESC->{$intron}}, $a[$descriptioncol]);
	  push(@{$DESC->{$intronS}}, $a[$descriptioncol]);
	  push(@{$DESC->{$intronE}}, $a[$descriptioncol]);
	}

	my $start_block = int($start / 1000);
	my $end_block = int($end / 1000);
	for(my $j=$start_block; $j<=$end_block; $j++) {
	  push(@{$feature_overlaps_block->{$chr}->{$j}},$intron);  # all introns that overlap the jth span of 1K bases
	}
      }
    }
  }
}
close(INFILE);

open(INFILE, $features_file) or die "file '$features_file' cannot open for reading.\n";
while($line = <INFILE>) {
  my $delim;
  chomp($line);
  if(!($line =~ /[^\s:,;]+:\d+-\d+/)) {
    print OUT "$line\n";
    next;
  }
  $line =~ /([^\s:,;]+:\d+-\d+)/;
  my  $feature = $1;
  my  $featureS = $feature;
  $featureS =~ s/:\d+-/:/;
  my $featureE = $feature;
  $featureE =~ s/-\d+$//;
  if($onecol eq 'true') {
    $delim = " ::: ";
  } else {
    $delim = "\t";
  }
  print OUT "$line\t"; 
  my $thing;
  if(defined $NAME->{$feature}) {
    $thing = $feature;
  } elsif(defined $NAME->{$featureS}) {
    $thing = $featureS;
  } elsif(defined $NAME->{$featureE}) {
    $thing = $featureE;
  } else {
    $feature =~ /(.*):(\d+)-(\d+)$/;
    my $feature_chr = $1;
    $featureS = $2;
    $featureE = $3;
    my $start_block = int($featureS / 1000);
    my $end_block = int($featureE / 1000);
    my $min = 100000000;
    my $flag = 0;
    my ($annotS, $annotN, $annotD) = ('', '', '');
    for(my $j=$start_block; $j<=$end_block; $j++) {
      my $NN = defined($feature_overlaps_block->{$feature_chr}->{$j}) ? @{$feature_overlaps_block->{$feature_chr}->{$j}} : 0;
      for(my $k=0; $k<$NN; $k++) {
	my $feature_o = $feature_overlaps_block->{$feature_chr}->{$j}->[$k];
	$feature_o =~ /.*:(\d+)-(\d+)$/;
	my $start_o = $1;
	my $end_o = $2;
	if(abs($featureS - $start_o) < $min) {
	  $annotN =  join(',', @{$NAME->{$feature_o}});
	  if (defined $genesymbolcol) {
	    $annotS = join(',', @{$SYMBOL->{$feature_o}});
	  }
	  if (defined $descriptioncol) {
	    $annotD =  join(' [|] ', @{$DESC->{$feature_o}});
	  }
	  $min = abs($featureS - $start_o);
	  $flag = 1;
	}
	if(abs($featureE - $start_o) < $min) {
	  $annotN =  join(',', @{$NAME->{$feature_o}});
	  if (defined $genesymbolcol) {
	    $annotS =  join(',', @{$SYMBOL->{$feature_o}});
	  }
	  if (defined $descriptioncol) {
	    $annotD = join(' [|] ', @{$DESC->{$feature_o}});
	  }
	  $min = abs($featureE - $start_o);
	  $flag = 1;
	}
	if(abs($featureS - $end_o) < $min) {
	  $annotN =  join(',', @{$NAME->{$feature_o}});
	  if (defined $genesymbolcol) {
	    $annotS =  join(',', @{$SYMBOL->{$feature_o}});
	  }
	  if (defined $descriptioncol) {
	    $annotD =  join(' [|] ', @{$DESC->{$feature_o}});
	  }
	  $min = abs($featureS - $end_o);
	  $flag = 1;
	}
	if(abs($featureE - $end_o) < $min) {
	  $annotN =  join(',', @{$NAME->{$feature_o}});
	  if (defined $genesymbolcol) {
	    $annotS =  join(',', @{$SYMBOL->{$feature_o}});
	  }
	  if (defined $descriptioncol) {
	    $annotD =  join(' [|] ', @{$DESC->{$feature_o}});
	  }
	  $min = abs($featureE - $end_o);
	  $flag = 1;
	}
      }
    }
    if($flag == 1 && $min <= 100000) {
      print OUT "$annotN";
      if (defined $genesymbolcol) {
	print OUT "$delim$annotS";
      }
      if(defined $descriptioncol && $outputdesc eq 'true') {
	print OUT "$delim$annotD";
      }
    }
    if($flag == 1 && $min > 100000) {
      print OUT "$min bases from: $annotN";
      if (defined $genesymbolcol) { 
	print OUT "$delim$annotS";
      }
      if(defined $descriptioncol && $outputdesc eq 'true') {
	print OUT "$delim$annotD";
      }
    }
    print OUT "\n";
    next;
  }
  print OUT  join(',', @{$NAME->{$thing}});
  if (defined $genesymbolcol) { 
    print OUT $delim . join(',', @{$SYMBOL->{$thing}});
  }
  if(defined $descriptioncol && $outputdesc eq 'true') {
    print OUT $delim . join(' [|] ', @{$DESC->{$thing}});
  }
  print OUT "\n";
}
print "got here\n";
