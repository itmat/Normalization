#!/usr/bin/env perl
if(@ARGV<3) {
    die "Usage: perl get_exonpercents.pl <sample directory> <cutoff> <outfile> [options]

<sample directory> 
<cutoff> cutoff %
<outfile> output exonpercents file with full path

option:
  -u  :  set this if you want to return only unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

  -nu :  set this if you want to return only non-unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

";
}

$U = "true";
$NU = "true";
$numargs = 0;
for($i=3; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$option_found = "true";
	$numargs++;
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

$total_u = 0;
$total_nu = 0;
$sampledir = $ARGV[0];
@a = split("/", $sampledir);
$dirname = $a[@a-1];
$id = $dirname;
$id =~ s/Sample_//;
$quantsfile_u = "$sampledir/Unique/$id.filtered_u_exonquants";
$quantsfile_nu = "$sampledir/NU/$id.filtered_nu_exonquants";
$temp_u = $quantsfile_u . ".temp";
$temp_nu = $quantsfile_nu . ".temp";
$cutoff = $ARGV[1];
$outfile = $ARGV[2];
$highfile = $outfile;
$highfile =~ s/.exonpercents.txt/.high_expressors.txt/;

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if (0 > $cutoff | 100 < $cutoff){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

if ($numargs eq "0"){
    open(INFILE_U, $quantsfile_u) or die "cannot find file '$quantsfile_u'\n";
    open(temp_u, ">$temp_u");
    while($line = <INFILE_U>){
	chomp($line);
	print temp_u "$line\n" unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	@a = split(/\t/, $line);
	$quant = $a[2];
	$total_u = $total_u + $quant unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
    }
    close(INFILE_U);
    close(temp_u);
    
    open(INFILE_NU, $quantsfile_nu) or die "cannot find file '$quantsfile_nu'\n";
    open(temp_nu, ">$temp_nu");
    while($line = <INFILE_NU>){
	chomp($line);
	print temp_nu "$line\n" unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	@a = split(/\t/, $line);
	$quant = $a[2];
	$total_nu = $total_nu + $quant unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
    }
    close(INFILE_NU);
    close(temp_nu);
}

else{
    if($U eq "true"){
	open(INFILE_U, $quantsfile_u) or die "cannot find file '$quantsfile_u'\n";
	open(temp_u, ">$temp_u");
	while($line = <INFILE_U>){
	    chomp($line);
	    print temp_u "$line\n" unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	    @a = split(/\t/, $line);
	    $quant = $a[2];
	    $total_u = $total_u + $quant unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(INFILE_U);
	close(temp_u);
    }
    if ($NU eq "true"){
	open(INFILE_NU, $quantsfile_nu) or die "cannot find file '$quantsfile_nu'\n";
	open(temp_nu, ">$temp_nu");
	while($line = <INFILE_NU>){
	    chomp($line);
            print temp_nu "$line\n" unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	    @a = split(/\t/, $line);
	    $quant = $a[2];
	    $total_nu = $total_nu + $quant unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(INFILE_NU);
	close(temp_nu);
    }
}

if($numargs eq "0"){
    open(IN_U, $temp_u);
    open(IN_NU, $temp_nu);
    open(OUT, ">$outfile");
    open(OUT2, ">$highfile");
    print OUT "exon\t%unique\t%non-unique\n";
    print OUT2 "exon\t%unique\t%non-unique\n";
    while(!eof IN_U and !eof IN_NU){
	$line_U = <IN_U>;
	$line_NU = <IN_NU>;
	chomp($line_U);
	chomp($line_NU);

	@au = split(/\t/, $line_U);
	$exonu = $au[0];
	$quantu = $au[2];
	$percent_u = int(($quantu / $total_u)* 10000 ) / 100;
	
	@anu = split(/\t/, $line_NU);
	$exonnu = $anu[0];
	$quantnu= $anu[2];
	$percent_nu = int(($quantnu / $total_nu)* 10000 ) / 100;
	
	print OUT "$exonu\t$percent_u\t$percent_nu\n";
	
	if ($percent_u >= $cutoff | $percent_nu >= $cutoff){
	    print OUT2 "$exonu\t$percent_u\t$percent_nu\n";
	}
    }
    close(IN_U);
    close(IN_NU);
    close(OUT);
    close(OUT2);
    `rm $temp_u $temp_nu`;
}
else{
    if($U eq "true"){
	open(IN_U, $temp_u);
	open(OUT, ">$outfile");
	open(OUT2, ">$highfile");
	print OUT "exon\t%unique\n";
	print OUT2 "exon\t%unique\n";
	while($line_U = <IN_U>){
	    chomp($line_U);

	    @au = split(/\t/, $line_U);
	    $exonu = $au[0];
	    $quantu = $au[2];
	    $percent_u = int(($quantu / $total_u)* 10000 ) / 100;

	    print OUT "$exonu\t$percent_u\n";

	    if ($percent_u >= $cutoff){
		print OUT2 "$exonu\t$percent_u\n";
	    }
	}
	close(IN_U);
	close(OUT);
	close(OUT2);
	`rm $temp_u`;
    }
    if($NU eq "true"){
	open(IN_NU, $temp_nu);
        open(OUT, ">$outfile");
        open(OUT2, ">$highfile");
        print OUT "exon\t%non-unique\n";
        print OUT2 "exon\t%non-unique\n";
        while($line_NU = <IN_NU>){
	    chomp($line_NU);

            @anu = split(/\t/, $line_NU);
            $exonnu = $anu[0];
            $quantnu = $anu[2];
            $percent_nu = int(($quantnu / $total_nu)* 10000 ) / 100;

            print OUT "$exonnu\t$percent_nu\n";

            if ($percent_nu >= $cutoff){
                print OUT2 "$exonnu\t$percent_nu\n";
            }
        }
        close(IN_NU);
        close(OUT);
        close(OUT2);
	`rm $temp_nu`;
    }
}


