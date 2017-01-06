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


my ($OUT_S, $OUT_A, $OUT_NS);
if ($filter eq "false"){
    my $pipecmd = "zcat $genesfile";
    open(GENE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
    if ($stranded eq "true"){
	$genesfile_s = $genesfile;
	$genesfile_s =~ s/.txt.gz$/.genefilter.sense.txt.gz/;
	$genesfile_a = $genesfile;
	$genesfile_a =~ s/.txt.gz$/.genefilter.antisense.txt.gz/;
	open($OUT_S, "| /bin/gzip -c >$genesfile_s") or die "error starting gzip $!";
	open($OUT_A, "| /bin/gzip -c >$genesfile_a") or die "error starting gzip $!";
    }
    else{
	$genesfile_ns = $genesfile;
	$genesfile_ns =~ s/.txt.gz$/.genefilter.txt.gz/;
	open($OUT_NS, "| /bin/gzip -c > $genesfile_ns") or die "error starting gzip $!" ;
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
		die "$id_f\t$id_r\t$ih_hi_f\t$ih_hi_r\n\"$genesfile\" is not in the right format.\n\n";
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
                    my @f = split(/\t/, $forward);
                    print $OUT_NS "$f[0]\t$f[1]\t$new_geneid_ns\t";
                    for(my $i=3;$i<@f;$i++){
                        print $OUT_NS "$f[$i]\t";
                    }
                    print $OUT_NS "\n";
                    my @r = split(/\t/, $reverse);
                    print $OUT_NS "$r[0]\t$r[1]\t$new_geneid_ns\t";
                    for(my $i=3;$i<@r;$i++){
                        print $OUT_NS "$r[$i]\t";
                    }
                    print $OUT_NS "\n";
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
		if ($sense eq "true"){
		    my @f = split(/\t/, $forward);
		    print $OUT_S "$f[0]\t$f[1]\t$new_geneid_s\t";
		    for(my $i=3;$i<@f;$i++){
			print $OUT_S "$f[$i]\t";
		    }
		    print $OUT_S "\n";
		    my @r = split(/\t/, $reverse);
                    print $OUT_S "$r[0]\t$r[1]\t$new_geneid_s\t";
		    for(my $i=3;$i<@r;$i++){
			print $OUT_S "$r[$i]\t";
                    }
                    print $OUT_S "\n";
		    push (@{$ID{$id_f}}, $ih_hi_f);
		}
		elsif ($anti eq "true"){
                    my @f = split(/\t/, $forward);
                    print $OUT_A "$f[0]\t$f[1]\t$new_geneid_a\t";
                    for(my $i=3;$i<@f;$i++){
                        print $OUT_A "$f[$i]\t";
                    }
                    print $OUT_A "\n";
                    my @r = split(/\t/, $reverse);
                    print $OUT_A "$r[0]\t$r[1]\t$new_geneid_a\t";
                    for(my $i=3;$i<@r;$i++){
                        print $OUT_A "$r[$i]\t";
                    }
                    print $OUT_A "\n";
		    push (@{$ID_A{$id_f}}, $ih_hi_f);
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
		print $OUT_NS "$forward\n";
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
		if ($sense eq "true"){
                    my @f = split(/\t/, $forward);
                    print $OUT_S "$f[0]\t$f[1]\t$new_geneid_s\t";
                    for(my $i=3;$i<@f;$i++){
                        print $OUT_S "$f[$i]\t";
                    }
                    print $OUT_S "\n";
		    push (@{$ID{$id_f}}, $ih_hi_f);
		}
		elsif ($anti eq "true"){
                    my @f = split(/\t/, $forward);
                    print $OUT_A "$f[0]\t$f[1]\t$new_geneid_a\t";
                    for(my $i=3;$i<@f;$i++){
			print $OUT_A "$f[$i]\t";
                    }
                    print $OUT_A "\n";
		    push (@{$ID_A{$id_f}}, $ih_hi_f);
		}
	    }
	}
    }
    close(GENE);
    if ($stranded eq "true"){
	close($OUT_A);
	close($OUT_S);
    }
    else{
	close($OUT_NS);
    }
}
if ($filter eq "true"){
    if ($stranded eq "false"){
	$genesfile_ns = $genesfile;
	$genesfile_ns =~ s/.txt.gz$/.genefilter.filter_highexp.txt.gz/;
	my $pipecmd = "zcat $genesfile_ns";
	open(GENE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
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
		    die "$id_f\t$id_r\t$ih_hi_f\t$ih_hi_r\n\"$genesfile_ns\" is not in the right format.\n\n";
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
	$genesfile_s =~ s/.txt.gz$/.genefilter.sense.filter_highexp.txt.gz/;
	$genesfile_a = $genesfile;
	$genesfile_a =~ s/.txt.gz$/.genefilter.antisense.filter_highexp.txt.gz/;
	my $pipecmd = "zcat $genesfile_s";
	open(GENE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
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
		    die "$id_f\t$id_r\t$ih_hi_f\t$ih_hi_r\n\"$genesfile_s\" is not in the right format.\n\n";
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
	my $pipecmd2 = "zcat $genesfile_a";
	open(GENE, '-|', $pipecmd2) or die "Opening pipe [$pipecmd2]: $!\n+";
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
		    die "$id_f\t$id_r\t$ih_hi_f\t$ih_hi_r\n\"$genesfile_a\" is not in the right format.\n\n";
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
if ($samfile =~ /.gz$/){
    my $pipecmd = "zcat $samfile";
    open(IN, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
}
else{
    open(IN, $samfile) or die "cannot open $samfile\n";
}
my $linecount = $output;
my $lc = 0;
my ($output_a, $linecount_a, $lc_a);
if ($stranded eq "true"){
    $output_a = $output;
    $output_a =~ s/.sam.gz$/.antisense.sam.gz/i;
    $output =~ s/.sam.gz$/.sense.sam.gz/i;
    $output_a =~ s/.sam$/.antisense.sam/i;
    $output =~ s/.sam$/.sense.sam/i;
    $linecount = $output;
    $linecount_a = $output_a;
    $lc_a = 0;
}
open(my $OUT, "| /bin/gzip -c >$output") or die "error starting gzip $!";
my $OUT_AA;
if ($stranded eq "true"){
    open($OUT_AA, "| /bin/gzip -c > $output_a")or die "error starting gzip $!";
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
		print $OUT "$read\n";
		$lc++;
	    }
	}
    }
    if ($stranded eq "true"){
	if (exists $ID_A{$id}){
	    for (my $i=0; $i<@{$ID_A{$id}};$i++){
		if ("$ID_A{$id}[$i]" eq "$ih_hi"){
		    print $OUT_AA "$read\n";
		    $lc_a++;
		}
	    }
	}
    }
}
close(IN);
close($OUT);
if ($stranded eq "true"){
    close($OUT_AA);
}
$linecount =~ s/sam.gz$/linecount.txt/;
open(LC, ">$linecount");
print LC "$output\t$lc\n";
close(LC);
if ($stranded eq "true"){
    $linecount_a =~ s/sam.gz$/linecount.txt/;
    open(LC_A, ">$linecount_a");
    print LC_A "$output_a\t$lc_a\n";
    close(LC_A);
}

print "got here\n";
