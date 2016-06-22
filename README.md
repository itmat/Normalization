# PORT 
## Preprocessor for Optimal RNA-Seq Transformation
**#RNA-Seq** **#Normalization** **#Quantification**
**PORT** offers two types of normalization: <br>__GENE Normalization__ and __EXON-INTRON-JUNCTION Normalization__.<br>

============================================================================================================================================================

### 0. Setting Up

####A. Clone the repository
Initial check-out:
    
    git clone https://github.com/itmat/Normalization.git

Make sure you have the latest version of PORT:

    git pull

####B. Input
##### i. Input Files

- Unaligned reads (fasta/fastq)
 - Raw sequence reads used to generate SAM/BAM.
 - Unaligned files can be gzipped.
- [Gene info files](https://github.com/itmat/Normalization/blob/master/about_cfg.md#2-gene-info)
- [Genome fa/fai](https://github.com/itmat/Normalization/blob/master/about_cfg.md#3-fa-and-fai)
- Aligned reads (SAM/BAM) 
 - SAM/BAM files need to have unique read ids. 
 - Required tags: **IH (or NH) and HI**.
 - __Paired End data: mated alignments need to be in adjacent lines.__

> If aligning with STAR v2.5.1a or higher, use "--outSAMunmapped Within KeepPairs" option.
 
##### ii. Input Directory Structure
The input files need to be organized into a specific directory structure for PORT to run properly.

- __Give `STUDY` directory a unique name.__
- Sample directories (Sample_1, Sample_2, etc) can have any name.
- Make sure the **unaligned reads** and **alignment outputs** (SAM/BAM files) are in each sample directory inside the `READS` folder.
- All alignment files (SAM/BAM files) **MUST have the same name** across samples. 

<pre>
STUDY
└── READS
    ├── Sample_1
    │   ├── Unaligned reads
    │   └── Aligned.sam/bam
    ├── Sample_2
    │   ├── Unaligned reads
    │   └── Aligned.sam/bam
    ├── Sample_3
    │   ├── Unaligned reads
    │   └── Aligned.sam/bam
    └── Sample_4
        ├── Unaligned reads
        └── Aligned.sam/bam

</pre>

####C. [Configuration File](https://github.com/itmat/Normalization/blob/master/about_cfg.md)
Get the `template_version.cfg` file from `/path/to/Normalization/` and follow the instructions in the config file. NORMALIZATION TYPE, DATA TYPE (stranded), CLUSTER INFO, GENE INFO, rRNA, FA and FAI, DATA VISUALIZATION and CLEANUP options need to be specified. See **[here](https://github.com/itmat/Normalization/blob/master/about_cfg.md)** for more information.

####D. File of Sample Directories and Unaligned Reads
##### i. File of Sample Directories
Create a text file listing the names of the sample directories (without path, sorted by condition). When running PORT you will enter the name of this file for the '--sample_dirs' argument. e.g. the file should look like this:
       
            Sample_1
            Sample_2
            Sample_3
            Sample_4

##### ii. File of Unaligned Reads (Both forward and reverse reads for paired end data)
Create a text file listing the full paths of the input fasta or fastq files. When running PORT you will enter the name of this file for the '--unaligned' argument. e.g. the file should look like this:

            /path/to/Sample_1.fwd.fq/fa
            /path/to/Sample_1.rev.fq/fa
            /path/to/Sample_2.fwd.fq/fa
            /path/to/Sample_2.rev.fq/fa
            /path/to/Sample_3.fwd.fq/fa
            /path/to/Sample_3.rev.fq/fa
            /path/to/Sample_4.fwd.fq/fa
            /path/to/Sample_4.rev.fq/fa

####E. Install [sam2cov](https://github.com/khayer/sam2cov/)
This is an optional step. You can use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM, STAR or GSNAP. sam2cov supports stranded data, but it assumes the reverse read is in the same orientation as the transcripts/genes (sense). __Please make sure you have the latest version of sam2cov__. 

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

========================================================================================================

### 1. How to run PORT

####A. Recommended Workflow
PORT has two parts: PART1 and PART2.<br>

- In PART1, PORT preprocesses the data using the [normalization factors](https://github.com/itmat/Normalization/tree/master/#iii-normalization-factors-statistics).
- In PART2, PORT performs normalization and quantification.

#####i. Run run_normalization with no pipeline option.<br>
If you do not provide any pipeline options, PORT will pause when all steps in PART1 completes.<br>
#####ii. Check expected number of reads and highly expressed features (exons, introns, and genes).<br>
You will have a chance to check the expected number of reads after normalization and the list of highly expressed exons and introns for Exon-Intron-Junction Normalization and the list of highly expressed genes for Gene Normalization. Samples that lower the normalized read depth can be removed from &lt;file of sample dirs> at this point.<br>
#####iii. Run run_normalization with -part2 option.<br>
Use -cutoff_highexp &lt;n> option if you choose to filter the high expressers.<br>

####B. Run PORT

    run_normalization --sample_dirs <file of sample_dirs> --loc <s> \
    --unaligned <file of fa/fqfiles> --alignedfilename <s> --cfg <cfg file> [options]

* --sample_dirs [&lt;file of sample dirs>](https://github.com/itmat/Normalization/tree/master/#i-file-of-sample-directories) : a file with the names of the sample directories
* --loc &lt;s> : full path of the directory with the sample directories (`READS`)
* --unaligned [&lt;file of fa/fqfiles>](https://github.com/itmat/Normalization/tree/master/#ii-file-of-unaligned-reads-both-forward-and-reverse-reads-for-paired-end-data) : file of **all** fa/fqfiles
* --alignedfilename &lt;s> : the name of aligned file (e.g. RUM.sam, RUM.bam, Aligned.out.sam, Aligned.out.bam)
* --cfg [<cfg file>](https://github.com/itmat/Normalization/tree/master/#c-configuration-file) : configuration file for the study
* option : <br>
     **[pipeline options]**<br>
     **-part1_part2** : Use this option if you want to run steps in PART1 and PART2 without pausing. <br>
     **-part2** : Use this option to resume the pipeline at PART2 after running PORT without any pipeline options. <br>
     **-alt_out &lt;s>** : Use this option to redirect the normalized data to an alternate output directory (full path) (Default: /path/to/studydir/NORMALIZED_DATA/) <br>
     **-h** : print this usage<br>
     **-v** : print version of PORT

      **[resume options]**<br>
      You may not change the normalization parameters with resume option.<br>
      **-resume** : Use this if you have a job that crashed or stopped. This runs a job that has already been initialized or partially run after the last completed step. It may repeat the last completed step if necessary.<br>
      **-resume_at "&lt;step>"** : Use this if you have a job that crashed or stopped. This resumes a job at "&lt;step>". **make sure full step name (found in log file) is given in quotes.**<br>(e.g. -resume_at "1   "STUDY.get_total_num_reads"")<br>

     **[normalization parameters]**<br>
     **-cutoff_highexp &lt;n>** : <br>is cutoff % value to identify highly expressed genes/exons/introns.<br>
                           The script will consider individual features (genes/exons/introns) accounting for greater than n(%) of the total reads as high expressers. The pipeline will remove the reads mapping to those features.<br>
                           (Default = 100; with the default cutoff, features (genes/exons/introns) expressed >5% will be reported, but will not remove any reads)<br>
     **-cutoff_lowexp &lt;n>** : <br>is cutoff counts to identify low expressers in the final spreadsheets (exon, intron, junction and gene).<br>
                          The script will remove features with sum of counts less than the set value from all samples.<br>
                          (Default = 0; with the default cutoff, features with sum of counts = 0 will be removed from all samples)<br>

     **[exon-intron-junction normalization only]**<br>
     **-novel_off** : set this if you DO NOT want to use the inferred exons/introns for quantification<br> (By default, the pipeline will use inferred exons/introns) <br>
     **-min &lt;n>** : is minimum size of inferred exon for get_novel_exons.pl script (Default = 10)<br>
     **-max &lt;n>** : is maximum size of inferred exon for get_novel_exons.pl script (Default = 1200)<br>
     **-depthExon &lt;n>** : the pipeline splits filtered sam files into reads mapping to 1,2,3,...,n exons and downsamples each separately.<br>
                   (Default = 20)<br>
     **-depthIntron &lt;n>** : the pipeline splits filtered sam files into reads mapping to 1,2,3,...,n introns and downsamples each separately.<br>
                   (Default = 10)<br>
     **-flanking_region &lt;n>** : <br>is used for generating list of flanking regions.<br>
                            by default, 5000 bp up/downstream of each gene will be considered a flanking region.<br>


This creates the `runall_normalization.sh` file in the `STUDY/shell_scripts` directory and runs the entire PORT pipeline. In addition to the STDOUT and STDERR files in `STUDY/logs`, this will create a log file called **`STUDY/logs/STUDY.run_normalization.log`**, which you can use to check the status.

####C. Stop/Kill PORT

All PORT job names begin with the unique `STUDY` name (e.g. "STUDY.get_total_num_reads). You can stop/kill a PORT run by killing jobs with the names that begin with `STUDY` (e.g. `bkill -J "STUDY*"`).

========================================================================================================

### 2. Output
####A. Output Directory Structure
You will find all log files and shell scripts in the `STUDY/logs` and `STUDY/shell_scripts` directory, respectively. Once you complete the normalization pipeline, your directory structure will look like this if you run both Gene and Exon-Intron-Junction Normalization (If your data are stranded, each FINAL_SAM directory will have sense and antisense directory inside). You may use '-alt_out' option to output NORMALIZED_DATA to an alternate location.:
<pre>
STUDY
│── READS
│   ├── sample1
│   ├── sample2
│   ├── sample3
│   └── sample4
├── STATS
│   ├── EXON_INTRON_JUNCTION
│   └── GENE
│── NORMALIZED_DATA
│   ├── EXON_INTRON_JUNCTION
│   │   ├── COV
│   │   ├── FINAL_SAM
│   │   │   ├── exonmappers
│   │   │   ├── intergenicmappers
│   │   │   ├── intronmappers
│   │   │   └── exon_inconsistent 
│   │   ├── JUNCTIONS
│   │   └── SPREADSHEETS
│   └── GENE
│       ├── COV
│       ├── FINAL_SAM
│       ├── JUNCTIONS
│       └── SPREADSHEETS
│── logs
└── shell_scripts
</pre>

####B. Output Files
This section describes the different output files generated by running Gene and/or Exon_Intron_Junction normalization (specified in the config file). Output files can be found in the `STUDY/STATS/*` and `STUDY/NORMALIZED_DATA/*` directories.
#####i. Normalized SAM/BAM
######-Exon-Intron-Junction Normalization:<br>
PORT outputs normalized exonmappers, intronmappers, intergenicmappers and exon inconsistent (exonmappers with inconsistent junctions) files to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM` directory. If the data are stranded, you will find sense and antisense exonmappers and intronmappers.<br>
######-Gene Normalization:<br>
PORT outputs normalized genemappers to `STUDY/NORMALIZED_DATA/GENE/FINAL_SAM` directory. If the data are stranded, you will find sense and antisense genemappers.<br>

#####ii. Feature Count Spreadsheets
######-Exon-Intron-Junction Normalization:<br>
PORT outputs feature (exon, intron, junctions) counts spreadsheets to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/SPREADSHEETS`. FINAL MIN spreadsheet has counts from Unique reads and FINAL MAX spreadsheet has counts from Unique+Non-Unique reads. If the data are stranded, you will find sense and antisense spreadsheets for exon and intron counts.<br>
######-Gene Normalization:<br>
PORT outputs gene counts spreadsheets to `STUDY/NORMALIZED_DATA/GENE/SPREADSHEETS`. FINAL MIN spreadsheet has counts from Unique reads that only map to one gene and FINAL MAX spreadsheet has counts from Unique+Non-Unique reads/multiple gene mappers. If the data are stranded, you will find sense and antisense spreadsheets.<br><br>If you use -cutoff_highexp option, PORT will estimate and put the counts of the filtered highly expressed genes back into the FINAL MIN spreadsheet and output an extra spreadsheet (`FINAL_master_list_of_genes_counts_MIN.STUDY.highExp.txt`) <br>

#####iii. Normalization Factors Statistics
######-Exon-Intron-Junction Normalization:<br>
`STUDY/STATS/exon-intron-junction_normalization_factors.txt` file provides summary statistics of the normalization factors used: 

- Total read count
- Ribosomal content
- Mitochondrial content
- Fragment length
- Proportion of Non-Unique reads (multi-mappers)
- Percent exon to non-exon signal
- 3' biased-ness
- Proportion of intergenic to intronic signal
- Sense vs. anti-sense transcription
- Very highly expressed and variable exons/introns

######-Gene Normalization:<br>
`STUDY/STATS/gene_normalization_factors.txt` file provides summary statistics	of the normalization factors used: 

- Total read count
- Ribosomal content
- Mitochondrial content
- Proportion of Non-Unique reads (multi-mappers)
- Proportion of genemappers
- Very highly expressed and variable genes
- Sense vs. anti-sense transcription

Percentage of reads mapping to each chromosome (`STUDY/STATS/percent_reads_chr*txt`) and percentage of highly expressed features (`STUDY/STATS/*/percent_high_expresser_*.txt`) are also provided (for both normalization types).
#####iv. Coverage/Junction Files 
Coverage (`STUDY/NORMALIZED_DATA/*/COV`) and Junctions (`STUDY/NORMALIZED_DATA/*/JUNCTION`) files are generated from uniquely merged sam files for each sample and can be used for data visualization.<br>
 

========================================================================================================



