# sRNAQC
## Purpose
A pipeline to process and QC sRNA sequence data: screens out low-quality reads, trims adapter sequences and generates a FastQC report.
## Requirements
Written in bash.

Requires:

fastq_quality_filter

cutadapt

fastx_collapser

FastQC

## Usage
Basic usage is:
```bash
bash sRNAQC.sh -i reads.fastq
```
sRNAQC accepts the following additional arguments (all of which have defaults already set):

-a (3' adapter sequence)

-c (number of cores, default=1)

-n (number of ambiguities in 3' adapter sequence, default=0)

-h display help message
