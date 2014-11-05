# PORT
## RNA-Seq Normalization & Quantification
**PORT** offers two types of normalization: <br>__GENE Normalization__ and __EXON-INTRON-JUNCTION Normalization__.<br>

============================================================================================================================================================

### 0. Setting Up

####A. Clone the repository
Please make sure you have the latest version of PORT.
    
    git clone https://github.com/itmat/Normalization.git

####B. Input
##### i. Input File
PORT takes aligned reads (SAM file) as input. You also need to provide unaligned reads (fa/fq file), gene info file, and genome fa/fai file.
 
##### ii. Input Directory Structure
The input files need to be in the correct format for PORT to run properly.

- Give `STUDY` directory a unique name.
- Make sure the unaligned reads and alignment outputs (SAM files) are in each sample directory inside the `READS` folder.
- All alignment files (SAM files) **MUST have the same name**.
- SAM files should have unique read ids.

<pre>
STUDY
└── READS
    ├── Sample_1
    │   ├── Unaligned reads
    │   └── Aligned.sam
    ├── Sample_2
    │   ├── Unaligned reads
    │   └── Aligned.sam
    ├── Sample_3
    │   ├── Unaligned reads
    │   └── Aligned.sam
    └── Sample_4
        ├── Unaligned reads
        └── Aligned.sam

</pre>

####C. Configuration File
Get the `template_version.cfg` file from `/path/to/Normalization/` and follow the instruction in the config file. NORMALIZATION TYPE, DATA TYPE (stranded), CLUSTER INFO, GENE INFO, FA and FAI, DATA VISUALIZATION and CLEANUP options need to be specified. See [here](https://github.com/itmat/Normalization/blob/master/about_cfg.md) for more information.

####D. File of Sample Directories and Unaligned Reads
##### i. File of Sample Directories
Create a file &lt;sample dirs> with the names of the sample directories (without path, sorted by condition).

       e.g. the <sample dirs> file should look like this:
            Sample_1
            Sample_2
            Sample_3
            Sample_4

##### ii. File of Unaligned Reads (Forward only)
Create a file &lt;file of input forward fa/fq files> with full path of input forward fa or forward fq files.

       e.g. the <file of input forward fa/fq files> file should look like this:
            /path/to/Sample_1.fwd.fq/fa
            /path/to/Sample_2.fwd.fq/fa
            /path/to/Sample_3.fwd.fq/fa
            /path/to/Sample_4.fwd.fq/fa

####E. Install [sam2cov](https://github.com/khayer/sam2cov/)
This is an optional step. You can use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM or STAR. sam2cov supports stranded data, but it assumes the reverse read is in the same orientation as the transcripts/genes. __Please make sure you have the lastest version of sam2cov__. 

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

========================================================================================================

### 1. Run PORT

####A. Recommended Workflow
PORT has two parts: PART1 and PART2.<br>
#####i. Run run_normalization with no pipeline option.<br>
If you do not provide any pipeline options, PORT will pause when all steps in PART1 completes.<br>
#####ii. Check expected number of reads and highly expressed features (exons, introns, and genes).<br>
You will have a chance to check the expected number of reads after normalization and the list of highly expressed exons and introns for Exon-Intron-Junction Normalization and the list of highly expressed genes for Gene Normalization. Samples that lower the normalized read depth can be removed from &lt;file of sample dirs> at this point.<br>
#####iii. Run run_normalization with -part2 option.<br>
Use -cutoff_highexp &lt;n> option if you choose to filter the high expressers.<br>

####B. Run Normalization Script

    run_normalization --sample_dirs <file of sample_dirs> --loc <s> \
    --unaligned <file of fa/fqfiles> --samfilename <s> --cfg <cfg file> [options]

* --sample_dirs &lt;file of sample dirs> : a file with the names of the sample directories
* --loc &lt;s> : full path of the directory with the sample directories (`READS`)
* --unaligned &lt;file of fa/fqfiles> : file of fa/fqfiles
* --samfilename &lt;s> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* --cfg <cfg file> : configuration file for the study
* option : <br>
     **[pipeline options]**<br>
     **-part1_part2** : Use this option if you want to run steps in PART1 and PART2 without pausing. <br>
     **-part2** : Use this option to resume the pipeline at PART2 after running PORT without any pipeline options. <br>

      **[resume options]**<br>
      You may not change the normalization parameters with resume option.<br>
      **-resume** : Use this if you have a job that crashed or stopped. This runs job that has already been initialized or partially run after the last completed step. It may repeat the last completed step if necessary.<br>
      **-resume_at "&lt;step>"** : Use this if you have a job that crashed or stopped. This resumes job at "&lt;step>". **make sure full step name (found in log file) is given in quotes.**<br>(e.g. "1   "STUDY.get_total_num_reads"")<br>

     **[data type]**<br>
     **-se** : set this if the data is single end, otherwise by default it will assume it's a paired end data<br>
     **-fa** : set this if the unaligned files are in fasta format<br>
     **-fq** : set this if the unaligned files are in fastq format<br>
     **-gz** : set this if the unaligned files are compressed<br>

     **[normalization parameters]**<br>
     **-cutoff_highexp &lt;n>** : <br>is cutoff % value to identify highly expressed genes/exons/introns.<br>
                           the script will consider genes/exons/introns with gene/exon/intronpercents greater than n(%) as high expressers,
                           remove the reads that map to those genes/exons/introns.<br>
                           (Default = 100; with the default cutoff, exons expressed >5% will be reported, but will not remove any reads)<br>
     **-cutoff_lowexp &lt;n>** : <br>is cutoff counts to identify low expressers in the final spreadsheets (exon, intron, junction and gene).<br>
                          the script will remove features with sum of counts less than <n> from all samples.<br>
                          (Default = 0; with the default cutoff, features with sum of counts = 0 will be removed from all samples)<br>

     **[exon-intron-junction normalization only]**<br>
     **-novel_off** : set this if you DO NOT want to use the inferred exons for quantification<br> (By default, the pipeline will use inferred exons) <br>
     **-min &lt;n>** : is minimum size of inferred exon for get_novel_exons.pl script (Default = 10)<br>
     **-max &lt;n>** : is maximum size of inferred exon for get_novel_exons.pl script (Default = 1200)<br>
     **-depthE &lt;n>** : the pipeline splits filtered sam files into 1,2,3...n exonmappers and downsamples each separately.<br>
                   (Default = 20)<br>
     **-depthI &lt;n>** : the pipeline splits filtered sam files into 1,2,3...n intronmappers and downsamples each separately.<br>
                   (Default = 10)<br>
     **-h** : print usage


This creates `runall_normalization.sh` file in `STUDY/shell_scripts` directory and runs the entire normalization pipeline. In addition to the STDOUT and STDERR files in `STUDY/logs`, this will create a log file called **`STUDY/logs/STUDY.run_normalization.log`**, which you can use to check the status.

========================================================================================================

### 2. Output
####A. Output Directory Structure
You will find all log files and shell scripts in `STUDY/logs` and `STUDY/shell_scripts` directory, respectively. Once you complete the normalization pipeline, your directory structure will look like this if you run both Gene and Exon-Intron-Junction Normalization (If your data is stranded, each FINAL_SAM directory will have sense and antisense directory inside):
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
│   │   │   └── undetermined
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
Output files can be found in `STUDY/STATS/*` and `STUDY/NORMALIZED_DATA/*` directory.
#####i. Normalized SAM/BAM
######-Exon-Intron-Junction Normalization:<br>
PORT outputs normalized exonmappers, intronmappers, and intergenicmappers files to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM` directory. If the data is stranded, you will find sense and antisense exonmappers and intronmappers.<br>
######-Gene Normalization:<br>
PORT outputs normalized genemappers to `STUDY/NORMALIZED_DATA/GENE/FINAL_SAM` directory. If the data is stranded, you will find sense and antisense genemappers.<br>

#####ii. Feature Count Spreadsheets
######-Exon-Intron-Junction Normalization:<br>
PORT outputs feature (exon, intron, junctions) counts speadsheets to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/SPREADSHEETS`. MIN spreadsheet has counts from Unique reads and MAX spreadsheet has counts from Unique+Non-Unique reads. If the data is stranded, you will find sense and antisense spreadsheets for exon and intron counts.<br>
######-Gene Normalization:<br>
PORT outputs gene counts speadsheets to `STUDY/NORMALIZED_DATA/GENE/SPREADSHEETS`. MIN spreadsheet has counts from Unique reads that only map to one gene and MAX spreadsheet has counts from Unique+Non-Unique reads/multiple gene mappers. If the data is stranded, you will find sense and antisense spreadsheets.<br>

#####iii. Normalization Factors Statistics
######-Exon-Intron-Junction Normalization:<br>
`STUDY/STATS/exon-intron-junction_normalization_factors.txt` file provides a summary statistics of the normalization factors used: total number of reads, %chrM, %non-unique reads, %ribosomal, %exonic, %one_exonmapper, %intergenic, %undetermined (and %senseExon, %senseIntron for stranded data). 
######-Gene Normalization:<br>
`STUDY/STATS/gene_normalization_factors.txt` file provides a summary statistics	of the normalization factors used: total number of reads, %chrM, %non-unique reads, %ribosomal, %genemappers, (and %senseGene for stranded data).<br>
Percentage of reads mapping to each chromosome (`STUDY/STATS/percent_reads_chr*txt`) and percentage of highly expressed features (`STUDY/STATS/*/percent_high_expresser_*.txt`) are also provided.
#####iv. Coverage/Junction Files 
Coverage (`STUDY/NORMALIZED_DATA/*/COV`) and Junctions (`STUDY/NORMALIZED_DATA/*/JUNCTION`) files are generated from uniquely merged sam files for each sample and can be used for data visualization.<br>
 

========================================================================================================



