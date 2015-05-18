#Phylogenomics 

Scripts for performing phylogenetic analyses of whole genome sequences.

###USAGE
Count-kmers.sh -- Shell script that uses Jellyfish for k-mer counting. Input is a genome fasta file and the output will be a sorted text file listing the abundance of all 18-mers that were found.

Glue-counts.pl -- A perl script to make a table from the jellyfish outputfile.

Create-trees.pl -- A perl script to take the table generated from Glue-counts and create a distance matrix followed by a phylogenetic tree.

Kmer-trees.pl -- A perl script that will do all of the above three scripts when I get everything sorted.
