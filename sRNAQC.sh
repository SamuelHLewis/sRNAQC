#!/bin/bash

# defaults for cores (single) and adapter ambiguities (none)
Adapter3="TGGAATTCTCGGGTGCCAAGG"
Adapter5="GTTCAGAGTTCTACAGTCCGACGATC"
Cores=1
AdaptAmb=False

# command line option parsing
while getopts ":a:c:g:i:n:h" opt; do
	case $opt in
		a)
			if [ $OPTARG = "" ]
			then
				# exit if 3' adapter is set as an empty string
				printf "ERROR: 3' adapter (-a) set as empty\n"
				exit 1
			else
				# set 3' adapter to user input
				printf "3' adapter (-a): $OPTARG\n"
				Adapter3=$OPTARG
			fi
			;;
		c)
			if [ $OPTARG -le 1 ]
			then
				# exit if <1 cores are specified
				printf "ERROR: cores (-c) must be >0\n"
				exit 1
			else
				# set number of cores to user input
				printf "cores (-c): $OPTARG\n"
				Cores=$OPTARG
			fi
			;;
		g)
			if [ $OPTARG = "" ]
			then
				# exit if 5' adapter is set as an empty string
				printf "ERROR: 5' adapter (-g) set as empty\n"
				exit 1
			else
				# set 5' adapter to user input
				printf "5' adapter (-g): $OPTARG\n"
				Adapter5=$OPTARG
			fi
			;;
		h)
			printf "Valid parameters are:\n-a (3' adapter sequence)\n-g (5' adapter sequence)\n-c (number of cores, default=1)\n-i (input file)\n-n (number of ambiguities in 3' adapter sequence, default=0)\n-h display help message\n"
			exit 1
			;;
		i)
			# set input file
			printf "Input file (-i): $OPTARG\n"
			InFile=$OPTARG
			;;
		n)
			# exit if adapter ambiguities are specified but <1 is given as option
			if [ $OPTARG -le 1 ]
			then
				printf "ERROR: ambiguities in adapter (-n) must be >0\n"
				exit 1
			fi
			# set number of adapter ambiguities to user input
			if [ $OPTARG -ge 1 ]
			then
				printf "ambiguities in adapter (-n): $OPTARG\n"
				AdaptAmb=$OPTARG
			fi
			;;
		\?)
			printf "ERROR: invalid parameter: -$OPTARG\nValid parameters are:\n-a (3' adapter sequence)\n-g (5' adapter sequence)\n-c (number of cores, default=1)\n-i (input file)\n-n (number of ambiguities in 3' adapter sequence, default=0)\n-h display help message\n"
			exit 1
			;;
		:)
			printf "Option -$OPTARG requires an argument\n"
			exit 1
			;;
	esac
done

###############
## CORE CODE ##
###############
# remove all files starting 'reads'
rm reads*
# filter out all reads with >10% bases with a Qphred of <20 (<99% certain)
printf "Filtering out low quality reads\n"
fastq_quality_filter -v -q 20 -p 90 -i $InFile -o reads_f.fastq
# trim adapters
# -e 0.05 specifies a 5% error rate (1 mismatch)
printf "Trimming adapters\n"
cutadapt --trimmed-only -a $Adapter3 -g $Adapter5 -m 17 -e 0.05 -o reads_f_t.fastq reads_f.fastq
if [ "$AdaptAmb" != "False" ]
then
	# trim 3 bases from 3' end of each read
	printf "Trimming $AdaptAmb adapter ambiguities from 3' end of each read\n"
	cutadapt -u -$AdaptAmb -o reads_f_t2.fastq reads_f_t.fastq
	rm reads_f_t.fastq
	mv reads_f_t2.fastq reads_f_t.fastq
fi

# collapse reads to unique reads
fastx_collapser -i reads_f_t.fastq -o reads_f_t_c.fasta

# remove ./fastqc if it already exists
rm -r ./fastqc
# make new dir for fastq results
mkdir ./fastqc
# run fastQC on file
printf "QCing reads\n"
~/bin/FastQC/fastqc -t $Cores -o ./fastqc reads_f_t.fastq

# recompress everything
files=( $(ls . | grep '\.f*') )
for i in ${files[*]}; do
	printf "Compressing $i\n"
	gzip $i
done