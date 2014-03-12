## Normalization

### 0. Setting Up

#####A. Clone the repository
    
    git clone git@github.com:itmat/Normalization.git

#####B. Input Directory Structure
Make sure your fastq/fasta files and alignment outputs(SAM files) are in each sample directory inside the `READS` folder.
<pre>
STUDY					
└── READS							
    ├── Sample_1
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa											
    │   └── Aligned.sam													  
    ├── Sample_2													      
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa											
    │   └── Aligned.sam													          
    ├── Sample_3											
    │   ├── fwd.fq/fa
    │   ├── rev.fq/fa														      
    │   └── Aligned.sam														          
    └── Sample_4											
        ├── fwd.fq/fa
        ├── rev.fq/fa															      
        └── Aligned.sam															          
</pre>	    																	    

#####C. Output Directory Structure
You will find all log files and shell scripts in `STUDY/logs` and `STUDY/shell_scripts` directory, respectively. Once you complete the normalization pipeline, your directory structure will look like this (before the Clean Up step):
<pre>
STUDY
│── READS
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
│── NORMALIZED_DATA
│   ├── exonmappers
│   │   ├── MERGED
│   │   ├── NU
│   │   └── Unique
│   ├── notexonmappers
│   │    ├── MERGED
│   │    ├── NU
│   │    └── Unique
│   ├── FINAL_SAM
│   │   ├── MERGED
│   │   ├── NU
│   │   └── Unique
│   └── Junctions
│
│── logs
│
└── shell_scripts
</pre>
   					
### 1. Run BLAST

##### A. File of Sample Directories
Create a file &lt;sample dirs> with the names of the sample directories (without path, sorted by condition). This file will be used throughout the pipeline.

       e.g. the <sample dirs> file should look like this:
            Sample_1
            Sample_2
            Sample_3
            Sample_4

##### B. Total Number of Reads
Get total number of reads from input fasta or fastq files.

      perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;file of input forward fa/fq files> :  a file with the full path of input forward fa or forward fq files

           e.g. the <file of input forward fa/fq files> file should look like this:
     		path/to/STUDY/READS/Sample_1/fwd.fq
	        path/to/STUDY/READS/Sample_2/fwd.fq
     		path/to/STUDY/READS/Sample_3/fwd.fq
	        path/to/STUDY/READS/Sample_4/fwd.fq

* option:<br>
  **-fa** : set this if the input files are in fasta format <br>
  **-fq** : set this if the input files are in fastq format

This will output a file called `total_num_reads.txt` to the `STUDY/READS` directory.

##### C. BLAST

      perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db> [options]

> `runblast.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;samfile name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;blast dir> : full path of the blast dir 
* &lt;db> : full path of the database 
* option:<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This outputs `*ribosomalids.txt` of samples to each sample directory (`STUDY/READS/Sample*/`).

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

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* option:<br>
  **-u** : set this if you want to return only unique mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This creates directories called `STUDY/READS/Sample*/Unique` and/or `STUDY/READS/Sample*/NU` and outputs `filtered.sam` files of all samples to the directories created. 

### 3. Quantify Exons
##### A. Create Master List of Exons
Get master list of exons from a UCSC gene info file.

    perl get_master_list_of_exons_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a file called `master_list_of_exons.txt` to the `READS` directory.

##### B. [optional step] : Filter Other High Expressors
This is an extra filter step that removes highly expressed exons.

 I. Run Quantify exons

 Run the following command with **&lt;output sam?> = false**. 

     perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

 > `quantify_exons.pl` available for running one sample at a time

 * &lt;sample dirs> : a file with the names of the sample directories
 * &lt;loc> : full path of the directory with the sample directories (`READS`)
 * &lt;exons> : `master_list_of_exons.txt` file
 * &lt;output sam?> : false
 * option:<br>
   **-NU-only** : set this for non-unique mappers<br>
   **-bsub** : set this if you want to submit batch jobs to LSF<br>
   **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

 This will output `exonquants` file of all samples to `Unique` and/or `NU` directory in each sample directory.

 II. Get High Expressors

      perl runall_get_high_expressors.pl <sample dirs> <loc> <cutoff> <annotation file> <exons> [options]

 * &lt;sample dirs> : a file with the names of the sample directories
 * &lt;loc> : full path of the directory with the sample directories (`READS`)
 * &lt;cutoff> : cutoff % value 
 * &lt;annotation file> : downloaded from UCSC known-gene track including at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the Linked Tables table.
 * &lt;exons> : `master_list_of_exons.txt` file
 * option:<br>
  **-u**  :  set this if you want to return only unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-nu** :  set this if you want to return only non-unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF.<br>
  **-qsub** : set this if you want to submit batch jobs to Sun Grid Engine.

 This will output `exonpercents.txt` and `high_expressors_annot.txt` files of all samples to each sample directory. It will also output `annotated_master_list_of_exons.txt` to `STUDY/READS` directory.

 III. Filter High Expressors

      perl filter_high_expressors.pl <sample dirs> <loc> <exons>

 * &lt;sample dirs> : a file with the names of the sample directories
 * &lt;loc> : full path of the directory with the sample directories (`READS`)
 * &lt;exons> : `master_list_of_exons.txt` file

 This will output a text file called `filtered_master_list_of_exons.txt` to `STUDY/READS` directory.

##### C. Run quantify exons

This step takes filtered sam files and splits them into 1, 2, 3 ... n exonmappers and notexonmappers (n = 20 if you don't use the -depth option).

Run the following command with **&lt;output sam?> = true**. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.txt` (or `master_list_of_exons.txt` if you skipped step 3B)
* &lt;output sam?> : true
* option:<br>
  **-depth &lt;n>** : by default, it will output 20 exonmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This outputs multiple files of all samples: `exonmappers.(1, 2, 3, 4, ... n).sam`, `notexonmappers.sam`, and `exonquants` file to `Unique` / `NU` directory inside each sample directory. 

##### D. Normalization Factors
* Ribo percents: 

         perl runall_get_ribo_percents.pl <sample dirs> <loc> [options]

       * &lt;sample dirs> : a file with the names of the sample directories 
       * &lt;loc> : full path of the directory with the sample directories (`READS`)
       * option : <br>
         **-bsub** : set this if you want to submit batch jobs to LSF<br>
	 **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

 It assumes there are files of ribosomal ids output from runblast.pl each with suffix "ribosomalids.txt" in each sample directory. This will output `ribosomal_counts.txt` and `ribo_percents.txt` to `READS` directory.

* Exon to nonexon signal:

         perl get_exon2nonexon_signal_stats.pl <sample dirs> <loc> [options]

       * &lt;sample dirs> : a file with the names of the sample directories 
       * &lt;loc> : full path of the directory with the sample directories (`READS`)
       * option:<br>
       **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
       **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

 This will output `exon2nonexon_signal_stats_Unique.txt` and/or `exon2nonexon_signal_stats_NU.txt` depending on the option provided to `READS` directory.

* One exon vs multi exons:

      	 perl get_1exon_vs_multi_exon_stats.pl  <sample dirs> <loc> [options]

       * &lt;sample dirs> : a file with the names of the sample directories <br>
       * &lt;loc> : full path of the directory with the sample directories (`READS`)
	* option:<br>
  	**-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
  	**-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

 This will output `1exon_vs_multi_exon_stats_Unique.txt` and/or `1exon_vs_multi_exon_stats_NU.txt` depending on the option provided to `READS` directory.

### 4. Quantify Introns
##### A. Create Master List of Introns

    perl get_master_list_of_introns_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a txt file called `master_list_of_introns.txt` to `READS` directory.

##### B. Run quantify introns

This step takes `notexonmappers.sam` files and splits them into 1, 2, 3 ... n intronmappers and intergenicmappers files (n = 10 if you don't use the -depth option). 

Run the following command with **&lt;output sam?> = true**. By default this will return unique intronmappers. Use -NU-only to get non-unique intronmappers:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file (with full path)
* &lt;output sam?> : true
* option : <br>
  **-depth &lt;n>** : by default, it will output 10 intronmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
 
This outputs multiple files of all samples: `intronmappers.(1, 2, 3, ... n).sam`, `intergenicmappers.sam`, and `intronquants` file to `Unique` / `NU` directory in each sample directory.

### 5. Downsample

##### A. Run head 
This identifies minimum line count of each type of exonmappers/intronmappers/intergenicmappers and downsamples each file by taking the minimum line count of rows from each file.
      
      perl runall_head.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-depthE &lt;n>** : set the exonmapper depth (by default, n = 20)<br>
  **-depthI &lt;n>** : set the intronmapper depth (by default, n = 10)

This will output the same number of rows from each file in each `sample_dir/Unique` and/or `sample_dir/NU` directory of the same type.

##### B. Concatenate head files

      perl cat_headfiles.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

This will create `STUDY/NORMALIZED_DATA`, `STUDY/NORMALIZED_DATA/exonmappers`, and `STUDY/NORMALIZED_DATA/notexonmappers` directories and output normalized exonmappers, intronmappers and intergenic mappers of all samples to the directories created.

##### C. Merge normalized SAM files

      perl make_final_samfile.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return merged final sam.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return merged final sam.

This will create `FINAL_SAM`. Then, depending on the option given, it will make `FINAL_SAM/Unique`, `FINAL_SAM/NU`, or `FINAL_SAM/MERGED` directory and output final sam files to the directories created. A tag will be added to each sequence indicating its type (XT:A:E for exonmappers, XT:A:I for intronmapper, and XT:A:G for intergenicmappers).

### 6. Run sam2junctions

By default, this will use merged final sam files as input. 
 
    perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> :the RUM gene info file 
* &lt;genome> : the RUM genome sequene one-line fasta file 
* option:<br>
  **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
 
This will create `STUDY/NORMALIZED_DATA/Junctions` directory and output `junctions_hq.bed`, `junctions_all.bed` and `junctions_all.rum` files of all samples.

### 7. Master table of features counts
#####A. Get Exonquants 
**a. Concatenate unique and non-unique normalized exonmappers**

If you want to quantify both Unique and Non-unique normalized exonmappers run this. If you're only interested in either Unique or Non-Unique exonmappers, go to step b.:

    perl cat_exonmappers_Unique_NU.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will create `NORMALIZED_DATA/exonmappers/MERGED` directory and output concatenated `exonmappers.norm.sam` file of all samples to the directory created.

**b. Run Quantify exons**

Run the following command with **&lt;output sam?> = false**. This will output merged exonquants by default. If merged exonmappers do not exist, it will output unique exonquants. Use -NU-only to get non-unique exonquants:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.txt` (or `master_list_of_exons.txt` file if you skipped step 3B)
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine
  			  
This outputs `exonquants` file of all samples to `NORMALIZED_DATA/exonmappers/MERGED` (or `NORMALIZED_DATA/exonmappers/Unique` or `NORMALIZED_DATA/exonmappers/NU`).

#####B. Get Intronquants

Run the following command with **&lt;output sam?> = false**. By default this will return unique intronquants. Use -NU-only to get non-unique intronquants:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file 
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This outputs `intronquants` file of all samples to `NORMALIZED_DATA/notexonmappers/Unique` or `NORMALIZED_DATA/notexonmappers/NU`.

#####C. Make Final Spreadsheets
**a. Run quants2spreadsheet and juncs2spreadsheet**

     perl make_final_spreadsheets.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique, otherwise by default it will return min and max spreadsheets.<br>
  **-nu** :  set this if you want to return only non-unique, otherwise by default it will return min and max spreadsheets.<br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will output `list_of_exons_counts`, `master_list_of_introns_counts`, and `master_list_of_junctions_counts` files to `STUDY/NORMALIZED_DATA` directory. 

**b. Annotate `list_of_exons_counts`**
     
     perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

> `annotate.pl` available for running one sample at a time

* &lt;file of features files> : a file with the names of the features files to be annotated

       	   e.g. the <file of feature files> file should look like this:
           	 list_of_exons_counts_MIN.txt
	    	 list_of_exons_counts_MAX.txt
	
* &lt;annotation file> : should be downloaded from UCSC known-gene track including at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the Linked Tables table.
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-bsub** : set this if you want to submit batch jobs to LSF<br>
  **-qsub** :  set this if you want to submit batch jobs to Sun Grid Engine

This will output `master_list_of_exons_counts` to `STUDY/NORMALIZED_DATA`.

**c. Filter low expressors**

     perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

* &lt;file of quants files> : a file with the names of the quants file

         e.g. the <file of quants files> file should look like this:
	      master_list_of_exons_counts_MIN.txt
	      master_list_of_exons_counts_MAX.txt
	      master_list_of_introns_counts_MIN.txt
	      master_list_of_introns_counts_MAX.txt
	      master_list_of_junctions_counts_MIN.txt
	      master_list_of_junctions_counts_MAX.txt

* &lt;number_of_samples> : number of samples
* &lt;cutoff> : cutoff value
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will output `FINAL_master_list_of_exons_counts`, `FINAL_master_list_of_introns_counts`, `FINAL_master_list_of_junctions_counts` to `STUDY/NORMALIZED_DATA`.

###8. Clean Up
#####A. Delete Intermediate SAM Files

     perl cleanup.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)

#####B. Convert SAM to BAM

     perl runall_sam2bam.pl <sample dirs> <loc> <sam file name> <fai file>

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : name of the alignment sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;fai file> : fai file 

This will covert SAM to BAM and delete the SAM. 
 