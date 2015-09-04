#!/bin/bash

## Shell script for starting the synthesis runs using Synopsys' Design Compiler.
################################################################################
VER="2014.09"              # Synopsys version
OUT="synthesis.log"        # Logfile for all synthesis outputs
SRC="comb-synth_eval.tcl"  # Tcl source file to be used for synthesis
################################################################################

synopsys-$VER dc_shell-xg-t -64bit -f $SRC -output_log_file $OUT
