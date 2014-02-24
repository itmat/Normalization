## Normalization

### 0. Setting Up

#####A. Clone the repository
    
    git clone git@github.com:itmat/Normalization.git

#####B. Input Directory Structure
Make sure your alignment outputs(sam files) are in each sample directory inside the `Aligned_DATA` folder.
<pre>
STUDY					
└── Aligned_DATA							
    ├── Sample_1											
    │   └── Aligned.sam													  
    ├── Sample_2													      
    │   └── Aligned.sam													          
    ├── Sample_3														      
    │   └── Aligned.sam														          
    └── Sample_4															      
        └── Aligned.sam															          
</pre>	    																	    

#####C. Output Directory Structure
Once you complete the normalization pipeline, your directory structure will look like this:
<pre>
STUDY
│── Aligned_DATA
│   ├── Sample_1
│   │   ├── NU
│   │   └── Unique
│   ├── Sample_2
│   │   ├── NU
│   │   └── Unique
│   ├── Sample_3
│   │   ├── NU
│   │   └── Unique
│   └── Sample_4
│       ├── NU
│       └── Unique
│
└── NORMALIZED_DATA
    ├── exonmappers
    │   ├── MERGED
    │   ├── NU
    │   └── Unique
    ├── notexonmappers
    │    ├── MERGED
    │    ├── NU
    │    └── Unique
    ├── FINAL_SAM
    │   ├── MERGED
    │   ├── NU
    │   └── Unique
    └── Junctions
</pre>
   					
### 1. Run BLAST
Create a file with the names of the sample directories (sorted by condition). This file will be used throughout the pipeline. 

       perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db>

> `runblast.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br> 
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;samfile name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;blast dir> : the blast dir (full path)
* &lt;db> : database (full path)

This outputs `ribosomalids.txt` and `total_num_reads.txt` of samples to each sample directory.

### 2. Run Filter
This step removes all rows from input sam file except those that satisfy all of the following:

  1. Unique mapper / Non-Unique mapper
  2. Both forward and reverse map consistently
  3. id not in (the appropriate) file specified in &lt;more ids>
  4. Only on a numbered chromosome, X or Y
  5. Is a forward mapper (script outputs forward mappers only). Will output &lt;target num> read (pairs) (put 0 for this arg if you want to output all).

Run the following command. By default it will return both unique and non-unique mappers.

    perl runall_filter.pl <sample dirs> <loc> <sam file name> [options]

> `filter_sam.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;sam file name> :  the name of sam file
* option:<br>
  **-u** : set this if you want to return only unique mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers

This creates directories called `Unique` and `NU` in each sample directory and outputs `filtered.sam` files of all samples to the directories created. 

### 3. Quantify Exons
##### A. Create Master List of Exons
Get master list of exons from a UCSC gene info file.

    perl get_master_list_of_exons_from_geneinfofile.pl <gene info file>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.

This outputs a file called `master_list_of_exons.txt`.

##### B. Run quantify exons

This step takes filtered sam files and splits them into 1, 2, 3 ... 20 exonmappers and notexonmappers. 

Run the following command with **&lt;output sam?> = true**. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;exons> : the `master_list_of_exons.txt` file (with full path)
* &lt;output sam?> : true
* option:<br>**-NU-only** : set this for non-unique mappers

This outputs multiple files of all samples: `exonmappers.(1, 2, 3, 4, ... 20).sam`, `notexonmappers.sam`, and `exonquants` file to `Unique` / `NU` directory inside each sample directory. 

##### C. Normalization Factors
* Ribo percents: 

       perl runall_get_ribo_percents.pl <sample dirs> <loc>

       * &lt;sample dirs> : a file with the names of the sample directories (without path)
       	 e.g. the &lt;sample dirs> should look like this:<br>
               Sample_1<br>
               Sample_2<br>
               Sample_3<br>
               Sample_4
       * &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)

It assumes there are files of ribosomal ids output from runblast.pl each with suffix "ribosomalids.txt". This will output `ribosomal_counts.txt` and `ribo_percents.txt` to `Aligned_DATA` directory.

* Exon to nonexon signal:

       perl get_exon2nonexon_signal_stats.pl <sample dirs> <loc>

       * &lt;sample dirs> : a file with the names of the sample directories (without path)
       	 e.g. the &lt;sample dirs> should look like this:<br>
              Sample_1<br>
              Sample_2<br>
              Sample_3<br>
              Sample_4
       * &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
       * option:<br>
       **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
       **-nu** :  set this if you want to return only non-unique statsotherwise by default it will return both unique and non-uniqe stats

 This will output `exon2nonexon_signal_stats_Unique.txt` and/or `exon2nonexon_signal_stats_NU.txt` depending on the option provided to `Aligned_DATA` directory.

* One exon vs multi exons:
  
	perl get_1exon_vs_multi_exon_stats.pl  <sample dirs> <loc>

       * &lt;sample dirs> : a file with the names of the sample directories (without path)
        e.g. the &lt;sample dirs> should look like this:<br>
              Sample_1<br>
              Sample_2<br>
              Sample_3<br>
              Sample_4
       * &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
	* option:<br>
  	**-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
  	**-nu** :  set this if you want to return only non-unique statsotherwise by default it will return both unique and non-uniqe stats

 This will output `1exon_vs_multi_exon_stats_Unique.txt` and/or `1exon_vs_multi_exon_stats_NU.txt` depending on the option provided to `Aligned_DATA` directory.

### 4. Quantify Introns
##### A. Create Master List of Introns

    perl get_master_list_of_introns_from_geneinfofile.pl <gene info file>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.

This outputs a txt file called `master_list_of_introns.txt`.

##### B. Run quantify introns

This step takes `notexonmappers.sam` files and splits them into 1, 2, 3 ... 10 intronmappers and intergenicmappers files. 

Run the following command with **&lt;output sam?> = true**. By default this will return unique intronmappers. Use -NU-only to get non-unique intronmappers:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;introns> : the `master_list_of_introns.txt` file (with full path)
* &lt;output sam?> : true
* option:<br>**-NU-only** : set this for non-unique mappers

This outputs multiple files of all samples: `intronmappers.(1, 2, 3, ... 10).sam`, `intergenicmappers.sam`, and `intronquants` file to `Unique` / `NU` directory inside each sample directory.

### 5. Downsample

##### A. Run head 
This identifies minimum line count of each type of exonmappers/intronmappers/intergenicmappers and downsamples each file by taking the minimum line count of rows from each file.
      
      perl runall_head.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)

This will output the same number of rows from each file in each `sample_dir/Unique` and/or `sample_dir/NU` directory of the same type.

##### B. Concatenate head files

      perl cat_headfiles.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

This will create `NORMALIZED_DATA`, `NORMALIZED_DATA/exonmappers`, and `NORMALIZED_DATA/notexonmappers` directories and output normalized exonmappers, intronmappers and intergenic mappers of all samples to the directories created.

##### C. Merge normalized SAM files

      perl make_final_samfile.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique, non-unique, and merged final sam files.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique, non-unique, and merged final sam files.

This will create `FINAL_SAM`. Then, depending on the option given, it will make `FINAL_SAM/Unique`, `FINAL_SAM/NU`, and/or `FINAL_SAM/MERGED` directory and output final sam files to the directories created.

### 6. Run sam2junctions

By default, this will use merged final sam files as input. 
 
    perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;genes> :the RUM gene info file (with full path)
* &lt;genome> : the RUM genome sequene one-line fasta file (with full path)
* option:<br>
  **-u**  :  set this if you want to return only unique junctions files, otherwis` file of all samples to the directory created.

**b. Run Quantify exons**

Run the following command with **&lt;output sam?> = false**. This will output merged exonquants by default. If merged exonmappers do not exist, it will output unique exonquants. Use -NU-only to get non-unique exonquants:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;exons> : the `master_list_of_exons.txt` file (with full path)
* &lt;output sam?> : false
* option:<br>**-NU-only** : set this for non-unique mappers
  			  
This outputs `exonquants` file of all samples.

#####B. Get Intronquants

Run the following command with **&lt;output sam?> = false**. By default this will return unique intronquants. Use -NU-only to get non-unique intronquants:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* &lt;introns> : the `master_list_of_introns.txt` file (with full path)
* &lt;output sam?> : false
* option:<br>**-NU-only** : set this for non-unique mappers

This outputs `intronquants` file of all samples.

#####C. Make Final Spreadsheets
**a. Run quants2spreadsheet and juncs2spreadsheet**

     perl make_final_spreadsheets.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories (without path)
      e.g. the &lt;sample dirs> should look like this:<br>
          Sample_1<br>
          Sample_2<br>
          Sample_3<br>
          Sample_4
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)
* option:<br>
  **-u**  :  set this if you want to return only unique, otherwise by default
         it will return min and max spreadsheets.<br>
  **-nu** :  set this if you want to return only non-unique, otherwise by default
         it will return min and max spreadsheets.

This will create `list_of_exons_counts`, `master_list_of_introns_counts`, and `master_list_of_junctions_counts` files. 

**b. Annotate `list_of_exons_counts`**
     
     perl run_annotate.pl <file of features files> <annotation file> <loc>

* &lt;file of features files> : a file with the names of the features files to be annotated
* &lt;annotation file> : should be downloaded from UCSC known-gene track including
at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease,\
 protein and gene fields from the Linked Tables table.
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)

This will generate `master_list_of_exons_counts`.

**c. Filter low expressors**

     perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

* &file of quants files> : a file with the names of the quants file without path
* &number_of_samples> : number of samples
* &cutoff> : cutoff value
* &lt;loc> : full path of the directory with the sample directories (Aligned_DATA)

This will output `FINAL_master_list_of_exons_counts`, `FINAL_master_list_of_introns_counts`, `FINAL_master_list_of_junctions_counts`.