#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl genefilter.pl <samfile> <sam2genes output> <outputfile>

<samfile> input samfile
<sam2gene output> output file from sam2gene.pl script
<output file> name of output file

options:
  -stranded : set this if the data are strand-specific.

  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.
 
  -filter_highexp : set this if you want to filter the reads that map to highly expressed genes.

* Only keeps a read pair/read when both forward and reverse read maps to gene.

";

if (@ARGV<3){
    die $USAGE;
}
my $pe = "true";
my $stranded = "false";
my $filter = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-filter_highexp'){
        $filter = "true";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $samfile = $ARGV[0];
my $genesfile = $ARGV[1];
my $output = $ARGV[2];

my %ID;
my %ID_A;
my ($genesfile_s, $genesfile_a, $genesfile_ns);



if ($filter eq "false"){
    open(GENE, $genesfile) or die "cannot find '$genesfile'\n";
    my $header = <GENE>;
    if ($stranded eq "true"){
	$genesfile_s = $genesfile;
	$genesfile_s =~ s/.txt$/.genefilter.sense.txt/;
	$genesfile_a = $genesfile;
	$genesfile_a =~ s/.txt$/.genefilter.antisense.txt/;
	open(OUT_S, ">$genesfile_s");
	print OUT_S "$header";
	open(OUT_A, ">$genesfile_a");
	print OUT_A "$header";
    }
    else{
	$genesfile_ns = $genesfile;
	$genesfile_ns =~ s/.txt$/.genefilter.txt/;
	open(OUT_NS, ">$genesfile_ns");
	print OUT_NS "$header";
    }
    while (my $forward = <GENE>){
	if ($pe eq "true"){
	    chomp($forward);
	    my $reverse = <GENE>;
	    chomp($reverse);
	    my @f = split(/\t/, $forward);
	    my @r = split(/\t/, $reverse);
	    my $id_f = $f[0];
	    my $ih_hi_f = $f[4];
	    my $id_r = $r[0];
	    my $ih_hi_r = $r[4];
	    my $geneid_f = $f[2];
	    my $geneid_r = $r[2];
	    if (($id_f ne $id_r) | ($ih_hi_f ne $ih_hi_r)){
		die "\"$genesfile\" is not in the right format.\n\n";
	    }
	    if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
		next;
	    }
	    if ($stranded eq "false"){
		my @id_f = split(",", $geneid_f);
		my $new_geneid_ns = "";
		my $mapped = "false";
		for (my $i=0; $i<@id_f;$i++){
		    my $fwd = $id_f[$i];
		    if ($geneid_r =~ /$fwd/){
			if ($new_geneid_ns =~ /^$/){
			    $new_geneid_ns .= "$fwd";
			}
			else{
			    $new_geneid_ns .= ",$fwd";
			}
			$mapped = "true";
		    }
		}
		if ($mapped eq "true"){
		    my $new_fwd = $forward;
		    $new_fwd =~ s/$geneid_f/$new_geneid_ns/;
		    my $new_rev = $reverse;
		    $new_rev =~ s/$geneid_r/$new_geneid_ns/;
		    print OUT_NS "$new_fwd\n$new_rev\n";
		    push (@{$ID{$id_f}}, $ih_hi_f);
		}
	    }
	    if ($stranded eq "true"){
		my @id_f = split(",", $geneid_f);
		my $anti = "false";
		my $sense = "false";
		my $new_geneid_s = "";
		my $new_geneid_a = "";
		for (my $i=0; $i<@id_f;$i++){
		    my $fwd = $id_f[$i];
		    my $fwd_tmp = $fwd;
		    $fwd_tmp =~ s/ANTI://g;
		    if ($fwd =~ /ANTI/){
			if ($geneid_r =~ /$fwd_tmp/){
			    $anti = "true";
			    if ($new_geneid_a =~ /^$/){
				$new_geneid_a .= "ANTI:$fwd_tmp";
			    }
			    else{
				$new_geneid_a .= ",ANTI:$fwd_tmp";
			    }
			}
		    }
		    else{
			if ($geneid_r =~ /ANTI:$fwd_tmp/){
			    $anti = "true";
			    if ($new_geneid_a =~ /^$/){
				$new_geneid_a .= "ANTI:$fwd_tmp";
			    }
			    else{
				$new_geneid_a .= ",ANTI:$fwd_tmp";
			    }
			    
			}
			elsif ($geneid_r =~ /$fwd_tmp/){
			    $sense = "true";
			    if ($new_geneid_s =~ /^$/){
				$new_geneid_s .= "$fwd_tmp";
			    }
			    else{
				$new_geneid_s .= ",$fwd_tmp";
			    }
			}
		    }
		}
		if ($anti eq "true"){
		    my $new_fwd = $forward;
		    $new_fwd =~ s/$geneid_f/$new_geneid_a/;
		    my $new_rev = $reverse;
		    $new_rev =~ s/$geneid_r/$new_geneid_a/;
		    print OUT_A "$new_fwd\n$new_rev\n";
		    push (@{$ID_A{$id_f}}, $ih_hi_f);
		}
		if ($sense eq "true"){
		    my $new_fwd = $forward;
		    $new_fwd =~ s/$geneid_f/$new_geneid_s/;
		    my $new_rev = $reverse;
		    $new_rev =~ s/$geneid_r/$new_geneid_s/;
		    print OUT_S "$new_fwd\n$new_rev\n";
		    push (@{$ID{$id_f}}, $ih_hi_f);
		}
	    }
	}
	else{
	    chomp($forward);
	    my @f = split(/\t/, $forward);
	    my $id_f = $f[0];
	    my $geneid_f = $f[2];
	    my $ih_hi_f = $f[4];
	    if ($geneid_f =~ /^$/){
		next;
	    }
	    if ($stranded eq "false"){
		print OUT_NS "$forward\n";
		push (@{$ID{$id_f}}, $ih_hi_f);
	    }
	    if ($stranded eq "true"){
		my $new_geneid_s = "";
		my $new_geneid_a = "";
		my @id_f = split(",", $geneid_f);
		my $anti = "false";
		my $sense = "false";
		for (my $i=0; $i<@id_f;$i++){
		    my $fwd = $id_f[$i];
		    my $fwd_tmp = $fwd;
		    $fwd_tmp =~ s/ANTI://g;
		    if ($geneid_f =~ /ANTI/){
			$anti = "true";
		    if ($new_geneid_a =~ /^$/){
			$new_geneid_a .= "ANTI:$fwd_tmp";
		    }
			else{
			    $new_geneid_a .= ",ANTI:$fwd_tmp";
			}
		    }
		    else{
			$sense = "true";
			if ($new_geneid_s =~ /^$/){
			    $new_geneid_s .= "$fwd_tmp";
			}
			else{
			    $new_geneid_s .= ",$fwd_tmp";
			}
		    }
		}
		if ($anti eq "true"){
		    my $new_fwd = $forward;
		    $new_fwd =~ s/$geneid_f/$new_geneid_a/;
		    print OUT_A "$new_fwd\n";
		    push (@{$ID_A{$id_f}}, $ih_hi_f);
		}
		if ($sense eq "true"){
		    my $new_fwd = $forward;
		    $new_fwd =~ s/$geneid_f/$new_geneid_s/;
		    print OUT_S "$new_fwd\n";
		    push (@{$ID{$id_f}}, $ih_hi_f);
		}
	    }
	}
    }
    close(GENE);
    close(OUT_A);
    close(OUT_S);
    close(OUT_NS);
}
if ($filter eq "true"){
    if ($stranded eq "false"){
	$genesfile_ns = $genesfile;
	$genesfile_ns =~ s/.txt$/.genefilter.filter_highexp.txt/;
	open(GENE, $genesfile_ns);
	my $header = <GENE>;
	while (my $forward = <GENE>){
	    if ($pe eq "true"){
		chomp($forward);
		my $reverse = <GENE>;
		chomp($reverse);
		my @f = split(/\t/, $forward);
		my @r = split(/\t/, $reverse);
		my $id_f = $f[0];
		my $ih_hi_f = $f[4];
		my $id_r = $r[0];
		my $ih_hi_r = $r[4];
		my $geneid_f = $f[2];
		my $geneid_r = $r[2];
		if (($id_f ne $id_r) || ($ih_hi_f ne $ih_hi_r) || ($geneid_f ne $geneid_r)){
		    die "\"$genesfile_ns\" is not in the right format.\n\n";
		}
		if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
		    next;
		}
		push (@{$ID{$id_f}}, $ih_hi_f);
	    }
	    else{
		chomp($forward);
		my @f = split(/\t/, $forward);
		my $id_f = $f[0];
		my $geneid_f = $f[2];
		my $ih_hi_f = $f[4];
		if ($geneid_f =~ /^$/){
		    next;
		}
                push (@{$ID{$id_f}}, $ih_hi_f);
            }
	}
	close(GENE);
    }
    if ($stranded eq "true"){
	$genesfile_s = $genesfile;
	$genesfile_s =~ s/.txt$/.genefilter.sense.filter_highexp.txt/;
	$genesfile_a = $genesfile;
	$genesfile_a =~ s/.txt$/.genefilter.antisense.filter_highexp.txt/;
	open(GENE, $genesfile_s);
        my $header = <GENE>;
        while (my $forward = <GENE>){
            if ($pe eq "true"){
                chomp($forward);
                my $reverse = <GENE>;
                chomp($reverse);
                my @f = split(/\t/, $forward);
                my @r = split(/\t/, $reverse);
                my $id_f = $f[0];
                my $ih_hi_f = $f[4];
                my $id_r = $r[0];
                my $ih_hi_r = $r[4];
                my $geneid_f = $f[2];
                my $geneid_r = $r[2];
                if (($id_f ne $id_r) || ($ih_hi_f ne $ih_hi_r) || ($geneid_f ne $geneid_r)){
                    die "\"$genesfile_s\" is not in the right format.\n\n";
                }
                if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
                    next;
                }
		push (@{$ID{$id_f}}, $ih_hi_f);
            }
            else{
                chomp($forward);
                my @f = split(/\t/, $forward);
                my $id_f = $f[0];
                my $geneid_f = $f[2];
                my $ih_hi_f = $f[4];
                if ($geneid_f =~ /^$/){
                    next;
                }
                push (@{$ID{$id_f}}, $ih_hi_f);
            }
        }
        close(GENE);
        open(GENE, $genesfile_a);
        $header = <GENE>;
        while (my $forward = <GENE>){
            if ($pe eq "true"){
                chomp($forward);
                my $reverse = <GENE>;
                chomp($reverse);
                my @f = split(/\t/, $forward);
                my @r = split(/\t/, $reverse);
                my $id_f = $f[0];
                my $ih_hi_f = $f[4];
                my $id_r = $r[0];
                my $ih_hi_r = $r[4];
                my $geneid_f = $f[2];
                my $geneid_r = $r[2];
                if (($id_f ne $id_r) || ($ih_hi_f ne $ih_hi_r) || ($geneid_f ne $geneid_r)){
                    die "\"$genesfile_a\" is not in the right format.\n\n";
                }
                if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
                    next;
                }
		push (@{$ID_A{$id_f}}, $ih_hi_f);
            }
            else{
                chomp($forward);
                my @f = split(/\t/, $forward);
                my $id_f = $f[0];
                my $geneid_f = $f[2];
                my $ih_hi_f = $f[4];
                if ($geneid_f =~ /^$/){
                    next;
                }
                push (@{$ID_A{$id_f}}, $ih_hi_f);
            }
        }
        close(GENE);
    }
}
open(IN, $samfile) or die "cannot find '$samfile'\n";
my $linecount = $output;
my $lc = 0;
my ($output_a, $linecount_a, $lc_a);
if ($stranded eq "true"){
    $output_a = $output;
    $output_a =~ s/.sam$/.antisense.sam/;
    $output =~ s/.sam$/.sense.sam/;
    $linecount = $output;
    $linecount_a = $output_a;
    $lc_a = 0;
}
open(OUT, ">$output");
if ($stranded eq "true"){
    open(OUT_A, ">$output_a");
}
while(my $read = <IN>){
    chomp($read);
    if ($read =~ /^@/){
	next;
    }
    my @r = split(/\t/, $read);
    my $id = $r[0];
    $read =~ /HI:i:(\d+)/;
    my $hi_tag = $1;
    $read =~ /(N|I)H:i:(\d+)/;
    my $ih_tag = $2;
    my $ih_hi = "$ih_tag:$hi_tag";
    if (exists $ID{$id}){
	for (my $i=0; $i<@{$ID{$id}};$i++){
	    if ("$ID{$id}[$i]" eq "$ih_hi"){
		print OUT "$read\n";
		$lc++;
	    }
	}
    }
    if ($stranded eq "true"){
	if (exists $ID_A{$id}){
	    for (my $i=0; $i<@{$ID_A{$id}};$i++){
		if ("$ID_A{$id}[$i]" eq "$ih_hi"){
		    print OUT_A "$read\n";
		    $lc_a++;
		}
	    }
	}
    }
}
close(IN);
close(OUT);
close(OUT_A);
$linecount =~ s/sam$/linecount.txt/;
open(LC, ">$linecount");
print LC "$output\t$lc\n";
close(LC);
if ($stranded eq "true"){
    $linecount_a =~ s/sam$/linecount.txt/;
    open(LC_A, ">$linecount_a");
    print LC_A "$output_a\t$lc_a\n";
    close(LC_A);
}
#`rm $genesfile`;
print "got here\n";
