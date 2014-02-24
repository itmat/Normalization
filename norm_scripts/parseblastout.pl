open(INFILE, $ARGV[0]);

while($line = <INFILE>) {
    chomp($line);
    if($line =~ /Query= (.*)/) {
        $id = $1;
        $line = <INFILE>;
        $line = <INFILE>;
        $line = <INFILE>;
        $line = <INFILE>;
        $line = <INFILE>;
        $line = <INFILE>;
        chomp($line);
        if($line =~ /\s\d+e-(\d+)/) {
            $exp = $1;
            if($exp >= 10) {
                $id =~ s/a$//;
                $id =~ s/b$//;
                if(!(exists $IDs{$id})) {
                    $IDs{$id}=1;
                    print "$id\n";
                }
            }
        }
    }
}
