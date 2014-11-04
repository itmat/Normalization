#!/usr/bin/env perl
use strict;
use warnings;
if (@ARGV < 2){
    die "usage: perl unique_merge_gnorm.pl <sample dirs> <loc> [options]

where:
<sample dirs> is  a file of sample directories
<loc> is the path to the sample directories

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.
";
}


my $NU = "true";
my $U = "true";
my $numargs = 0;
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs++;
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

my $LOC = $ARGV[1];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $norm_dir = $loc_study."NORMALIZED_DATA/GENE/FINAL_SAM/";
my $norm_merged_dir = $norm_dir . "/merged";
unless (-d $norm_merged_dir){
    `mkdir $norm_merged_dir`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my ($genefile, $genefile_a);
    my $outfile = "$norm_merged_dir/$id.merged.sam";
    open(OUTFILE, ">$outfile");
    if ($numargs eq '0'){    
	$genefile = "$norm_dir/sense/$id.gene.norm.sam";
	$genefile_a = "$norm_dir/antisense/$id.gene.norm.sam";
    }
    elsif ($U eq "true"){
	$genefile = "$norm_dir/sense/$id.gene.norm_u.sam";
	$genefile_a = "$norm_dir/antisense/$id.gene.norm_u.sam";
    }
    elsif ($NU eq "true"){
	$genefile = "$norm_dir/sense/$id.gene.norm_nu.sam";
	$genefile_a = "$norm_dir/antisense/$id.gene.norm_nu.sam";
    }
    #identify common string and get chr names
    my $common_str = "";
    my @NAME;
    my %CHR = ();
    open(GENE, $genefile) or die "cannot find file \"$genefile\"\n";
    while (<GENE>){
	if (1..1000){
	    if ($_ =~ /^@/){
		next;
	    }
	    my @a = split (/\t/, $_);
	    my $seqname = $a[0];
	    $seqname =~ s/[^A-Za-z0-9 ]//g;
	    push(@NAME, $seqname);
	}
    }
    close(GENE);

    my $last_1000 = `tail -1000 $genefile_a`;
    my @tail = split(/\n/, $last_1000);
    for my $seq (@tail){
	if ($seq !~ /^@/){
	    my @a = split (/\t/, $seq);
	    my $seqname = $a[0];
	    $seqname =~ s/[^A-Za-z0-9 ]//g;
	    push(@NAME, $seqname);
	}
    }

    $common_str = &LCP(@NAME);
    my %READ_HASH;
    # READ IN FILES
    # exonmapper file
    open(GENE, $genefile);
    while(my $line = <GENE>){
	chomp($line);
	if ($line =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $line);
	my $readname = $a[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	my $chr = $a[2];
	my ($HI_tag, $IH_tag);
	if ($line =~ /(N|I)H:i:(\d+)/){
	    $line =~ /(N|I)H:i:(\d+)/;
	    $IH_tag = $2;
	}
	if ($line =~ /HI:i:(\d+)/){
	    $line =~ /HI:i:(\d+)/;
	    $HI_tag = $1;
	}
	my $for_hash = "$readname:$IH_tag:$HI_tag";

	if (exists $READ_HASH{$chr}{$for_hash}){
	    next;
	}
	else{
	    print OUTFILE "$line\n"; 
	    $READ_HASH{$chr}{$for_hash} = 1;
	}
    }
    close(GENE);
    open(GENE_A, $genefile_a);
    while(my $line = <GENE_A>){
	chomp($line);
	if ($line =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $line);
	my $readname = $a[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	my $chr = $a[2];
	my ($HI_tag, $IH_tag);
	if ($line =~ /(N|I)H:i:(\d+)/){
	    $line =~ /(N|I)H:i:(\d+)/;
	    $IH_tag = $2;
	    }
	if ($line =~ /HI:i:(\d+)/){
	    $line =~ /HI:i:(\d+)/;
		$HI_tag = $1;
	}
	my $for_hash = "$readname:$IH_tag:$HI_tag";
	if (exists $READ_HASH{$chr}{$for_hash}){
	    next;
	}
	else{
	    print OUTFILE "$line\n";
	    $READ_HASH{$chr}{$for_hash} = 1;
	}
    }
    close(GENE_A);
}
close(INFILE);


print "got here\n";

sub LCP {
    return '' unless @_;
    return $_[0] if @_ == 1;
    my $i          = 0;
    my $first      = shift;
    my $min_length = length($first);
    foreach (@_) {
        $min_length = length($_) if length($_) < $min_length;
    }
  INDEX: foreach  my $ch ( split //, $first ) {
      last INDEX unless $i < $min_length;
      foreach  my $string (@_) {
	  last INDEX if substr($string, $i, 1) ne $ch;
      }
  }
    continue { $i++ }
    return substr $first, 0, $i;
}
