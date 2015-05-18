#!/bin/sh

#  Count-kmers.sh
#  
#
#  Created by Mike Nelson on 5/18/15.
#

BASE=`basename $1`

jellyfish count -m 18 -s 5300000 -o $BASE.jf -L 0  $1
jellyfish dump $BASE.jf | paste - - | tr -d '>' >$BASE.txt