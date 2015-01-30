use warnings;
use strict;

my $USAGE = "perl get_list_for_intronquants.pl <loc> [option]

<loc> is where the sample directories are

option: 
 -novel: use this option to use the study-specific master list of introns
         to get the list for intron quantification.

";

if (@ARGV<1){
    die $USAGE;
}
my $novel = "false";
for(my $i=1;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-novel'){
	$option_found = "true";
	$novel = "true";
    }
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}

my $LOC = $ARGV[0];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];

my $master_list = "$LOC/master_list_of_introns.txt";
my $flanking = "$LOC/list_of_flanking_regions.txt";
my $final_list = "$LOC/list_for_intronquants.txt";
if ($novel eq "true"){
    $master_list =~ s/txt$/$study.txt/;
    $final_list =~ s/txt/$study.txt/;
}

unless (-e $master_list){
    die "cannot find file '$master_list'\n";
}

unless (-e $flanking){
    die "cannot find file '$flanking'\n";
}

my $x = `cat $master_list $flanking > $final_list`;

print "got here\n";
