#!/bin/bash

## Shell script for starting the synthesis runs using Synopsys' Design Compiler.

################################################################################
VER="2015.06"                         # Synopsys version
OUT="synthesis.log"                   # Logfile for all synthesis outputs
SRC="scripts/sequ-synth_eval.tcl"     # Tcl source file to be used for synthesis
################################################################################

synopsys-$VER dc_shell -f $SRC -output_log_file $OUT
