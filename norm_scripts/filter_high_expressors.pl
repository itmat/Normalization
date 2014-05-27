#!/usr/bin/env perl
if(@ARGV < 3) {
    die  "usage: perl filter_high_expressors.pl <sample dirs> <loc> <exons> [options]

where
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> the study specific master list of exons or master list of exons file

[option]
  -u  :  set this if you want to filter only unique expressors, otherwise by default
         it will use both unique and non-unique.

  -nu :  set this if you want to filter only non-unique expressors, otherwise by default
         it will return both unique and non-unique.

";
}

$LOC = $ARGV[1];
$exons = $ARGV[2];
$new_exons = $exons;
$new_exons =~ s/master_list/filtered_master_list/;
$annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;

$U = "true";
$NU = "true";
$numargs = 0;
for($i=3; $i<@ARGV; $i++){
    $option_found = 'false';
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
    if($option_found eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while ($line = <INFILE>){
    chomp($line);
    $id = $line;
    $id =~ s/Sample_//;
    $dir = $line;
    $file = "$LOC/$dir/$id.high_expressors_annot.txt";
    open(IN, "<$file");
    @genes = <IN>;
    close(IN);
    foreach $gene (@genes){
	chomp($gene);
	@a = split(/\t/, $gene);
	if (@a > 3){
           if ($numargs eq '0'){
	      $list = $a[4];
           }
           else{
              $list = $a[3];
           }
	   @b = split(',', $list);
	   for ($i=0; $i<@b; $i++){
		$HIGH_GENE{$b[$i]} = $b[$i];
	   }
	}
    }
}
close(INFILE);

open(INFILE, "<$annotated_exons") or die "cannot find \"$annotated_exons\"\n";
@lines = <INFILE>;
close(INFILE);
foreach $line (@lines){
    chomp($line);
    $flag = 0;
    @l = split(/\t/, $line);
    $list = $l[2];
    $exon = $l[0];
    $exon =~ s/exon://;
    $MASTER_EXON{$exon} = $exon;
    @b = split(',', $list);
    for ($i=0; $i<@b; $i++){
	foreach $g (keys %HIGH_GENE){
	    if ($g eq $b[$i]){
		$flag = 1;
	    }
	}
    }
    if ($flag == 1){
	delete $MASTER_EXON{$exon};
    }
}

open(NEW, ">$new_exons");
foreach $exon (keys %MASTER_EXON){
    print NEW "$exon\n";
}
close(NEW);
print "got here\n";
