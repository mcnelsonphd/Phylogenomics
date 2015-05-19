#!/usr/bin/env perl
#
# Script to take a list of genome sequences and count the kmers present.
# The input list file is a tab-delimited, one entry per line format of GenomeID:file-path pairs.
# Genome files should be in fasta/multi-fasta format.
# Output file is a tab-delimited text file named with the GenomeID
# User specifies the kmer size during execution, which will be appended to the sorted output filename (_Nmer.txt)
#
# NB: Uses jellyfish to actually count kmers due to its speed over doing so in pure perl.
#     This must be present somewhere in the users PATH in order for script to work.
#
# Created by: Michael C. Nelson
# Version: 1
# Created on: 2015-05-19
# Revised on: 2015-05-19
######################################################################################################

use strict;
#use warnings;
use FindBin;
use File::Copy;
use Time::Piece;
use Time::Seconds;
use Getopt::Long;
use Scalar::Util qw(openhandle);

###### Initial variable instancing ######
my $kmer = 12;
my $outdir;
my $input;
my $logfile;
my $cpus = 4;
my $starttime = localtime;
my $fp = find_exe("jellyfish");
err("Can't find Jellyfish in your \$PATH") if !$fp;

my @Options;
setOptions();

if ($outdir) {
    if (-d $outdir){
        err("Output directory already exists, choose a new name for --outdir that is not $outdir");
    }
    else {
        msg("Creating $outdir to put results into.");
        runcmd("mkdir -p \Q$outdir\E")
    }
    $logfile = "$outdir/$kmer\mer_tables.log";    
}
else {
    $logfile = "$kmer\mer_tables.log";
}
open LOG, '>', $logfile or err("Can't open logfile");
msg("Began running Make_kmer_tables.pl at $starttime");
msg("Will use maximum of $cpus cores.");
msg("Writing log to: $logfile");


###### ACTUAL WORK GETS DONE HERE ######

if ($input == '') {
    usage();
}
open(IN, $input) or msg("Could not open input file.\n");
msg("Using $input as the input file.");

while (<IN>) {
    my @line = split(/\t/, $_);
    my $genomeID = $line[0];
    my $genomeFP = $line[1];
    msg("Processing genome $genomeID using the file $genomeFP");
    if ($outdir) {
        runcmd("jellyfish count -t $cpus -m $kmer -o $outdir/$genomeID.jf -s 7000000 $genomeFP");
        runcmd("jellyfish dump -t -c $outdir/$genomeID.jf | sort > $outdir/$genomeID.tmp");
        open(OUT, ">$outdir/head.tmp") or die;
        print OUT "kmer\t$genomeID\n";
        close OUT;
        runcmd("cat $outdir/head.tmp $outdir/$genomeID.tmp > $outdir/$genomeID\_$kmer\mers.txt");
        unlink("$outdir/head.tmp", "$outdir/$genomeID.jf", "$outdir/$genomeID.tmp");
    }
    else {
        runcmd("jellyfish count -t $cpus -m $kmer -o $genomeID.jf -s 7000000 $genomeFP");
        runcmd("jellyfish dump -t -c $genomeID.jf | sort > $genomeID.tmp");
        open(OUT, ">head.tmp") or die;
        print OUT "kmer\t$genomeID\n";
        close OUT;
        runcmd("cat head.tmp $genomeID.tmp > $genomeID\_$kmer\mers.txt");
        unlink("head.tmp", "$genomeID.jf", "$genomeID.tmp");
    }
}

my $endtime = localtime;
my $walltime = $endtime - $starttime;
my $pretty = sprintf "%.2f minutes", $walltime->minutes;
msg("Finished processing. Total time taken was: $pretty");

###### Sub-routines ######
sub find_exe {
    my($bin) = shift;
    for my $dir (File::Spec->path) {
        my $exe = File::Spec->catfile($dir, $bin);
        return $exe if -x $exe;
    }
    return;
}

sub runcmd {
    system(@_)==0 or err("Could not run command:", @_);
}

sub msg {
    my $t = localtime;
    my $line = "[".$t->hms."] @_\n";
    print LOG $line if openhandle(\*LOG);
    print STDERR $line;
}

sub err {
  msg(@_);
  exit(2);
}

sub setOptions {
    @Options = (
    'Mandatory:',
    {OPT=>"input=s", VAR=>\$input, DESC=>"The input table of GenomeID:filepaths to use for analysis"},
    'Options:',
    {OPT=>"kmer=i", VAR=>\$kmer, DESC=>"The kmer to use for analysis [DEFAULT=$kmer]"},
    {OPT=>"outdir=s", VAR=>\$outdir, DEFAULT=>'', DESC=>"Output folder"},
    {OPT=>"cpus=i", VAR=>\$cpus, DESC=>"Numer of CPUs to use for counting. [DEFAULT=$cpus]"},
    'Help:',
    {OPT=>"help", VAR=>\&usage, DESC=>"Print this help message."},
    );
    
    (!@ARGV) && (usage());
    
    &GetOptions(map {$_->{OPT}, $_->{VAR}} grep { ref } @Options) || usage();
    
    # Now setup default values.
    foreach (@Options) {
        if (ref $_ && defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
            ${$_->{VAR}} = $_->{DEFAULT};
        }
    }
}

sub usage {
    print STDERR
    "\nMake_kmer_tables.pl: A jellyfish wrapper for creating kmer tables for genome sequences.\n\n",
    "Usage:\tMake_kmer_tables.pl [options] --input file_list.txt\n\n";
    foreach (@Options) {
        if (ref) {
            my $def = defined($_->{DEFAULT}) ? " [DEFAULT='$_->{DEFAULT}']" : "";
            my $opt = $_->{OPT};
            $opt =~ s/!$//;
            $opt =~ s/=s$/ [XXX]/;
            $opt =~ s/=i$/ [int]/;
            printf STDERR "  --%-15s %s%s\n", $opt, $_->{DESC}, $def;
        }
        else {
            print STDERR "$_\n";
        }
    }
    print "\n";
    exit(1);
}