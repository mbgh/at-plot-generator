################################################################################
##
## Author:       Michael Muehlberghuber
## Filename:     comb-synth_eval.tcl
## Created:      Fri Sep  4 17:34:47 2015 (+0200)
## Last-Updated: Fri Sep  4 17:39:43 2015 (+0200)
## 
## Description:  Synthesis script for evaluating the size and the timing
##               information of a certain design for several timing
##               constraints.
## 
################################################################################


################################################################################
#####                                                                          #
#####     Settings                                                             #
#####                                                                          #
################################################################################

## Name of the VHDL entity to be evaluated.
set entity EntityName

## Name of the library to be used.
set lib work

## Maximum frequencies respectively maximum I/O delays in nanoseconds, for which
## the design should be synthesized.
set maxDelays {
		2.00
    1.60
    1.40
    1.20
		1.00
		0.90
		0.80
		0.70
		0.65
		0.60
		0.55
		0.50
		0.45
		0.40
		0.20
		0.00
}

## Directory to be used as root for all the runs.
set runDir "synth_eval/$entity"

## Number of cores to be used for the synthesis runs.
set cpuCores 6
################################################################################


################################################################################
#####                                                                          #
#####     Start of Actual Script                                               #
#####                                                                          #
################################################################################

## Get global (comprising all synthesis runs) start time.
set globalStartTime "[clock seconds]"

## Create the (root-)directory for the current runs.
file mkdir $runDir

## Create the library in the run directory.
define_design_lib $lib -path ./$runDir/$lib

## Log file to which all the (terminal) outputs should be written. Setting this
## file is done via the 'sh_output_log_file' variable provided by the Design
## Compiler. This is equal to providing the log file during the startup of the
## Design Compiler using the '-output_log_file' parameter. Since by default the
## outputs get appended to the file, we remove it first.
set synthOutputs "$runDir/synthesis_outputs.log"
set sh_output_log_file $synthOutputs

## File providing some information about the synthesis runs going on.
set runLog [open "$runDir/synthesis_status.log" w]

## Set the format of the time for start/stop times.
set timeFormat "%H:%M:%S"

## Counter for counting the number of runs (depending on the number of
## periods/max delays and the architectures/confirgures defined).
set run 0

## Set the number of CPU cores to be used for synthesis
set_host_options -max_cores $cpuCores

## Provide some information about the synthesis runs to be started into the run
## log file.
set dels [llength $maxDelays]
set runs $dels
puts $runLog "##"
puts $runLog "## RUNNING SYNTHESIS INFORMATION"
puts $runLog "##"
puts $runLog "## Synthesized Entity:           $entity"
puts $runLog "## Number of Timing Constraints: $dels"
puts $runLog "## Overall Synthesis Runs:       $runs"
puts $runLog "## Number of CPU Cores Used:     $cpuCores"
puts $runLog "## Start of Synthesis Runs:      [clock format ${globalStartTime}]"
puts $runLog "##"
flush $runLog

## Perform synthesis runs for all defined architectures/configurations and
## periods/max delays.
foreach maxDelay $maxDelays {
		
		## Increment the synthesis runs counter.
		incr run

		## Start time of the compilation run.
		set startTime "[clock seconds]"

		## Provide some information about the current run.
		puts -nonewline $runLog "## Starting synthesis run $run of $runs ($entity-${maxDelay}ns) ... Start: "
		puts -nonewline $runLog "[clock format $startTime -format ${timeFormat}]"
		flush $runLog

		## Subdirectory for current run with a certain period.
		set currRunDir "$runDir/${entity}_${maxDelay}ns"

		## For the reports directory, use a period-specific suffix.
		set reportsDir "${currRunDir}/reports"

		## For the DDC directory, use a period-specific suffix.
		set ddcDir "${currRunDir}/ddc"

		## Create the required directories.
		file mkdir $currRunDir
		file mkdir $reportsDir
		file mkdir $ddcDir

		## Start from a fresh design.
		remove_design -design
		sh rm -rf $lib/*

		## Analyze the source files.
		analyze -library $lib -format vhdl { \
	    source1.vhd \
			source2.vhd \
      source3.vhd
		}
      
		## Elaborate the current configuration.
		elaborate $entity


		## Setting the constraints.
		############################################################################

		## Since we are investigating a fully combinational design, we have to set
		## the min/max delays instead of the clock period.
		set_max_delay ${maxDelay} -from [all_inputs] -to [all_outputs]

		## Set a rough input delay for all inputs.
		set_input_delay 0.1 [all_inputs]
                
		## Set a rough output delay for all outputs.
		set_output_delay 0.1 [all_outputs]
                
		## Let a mid-sized two-input XOR drive all the data inputs. Note that the
		## following line depends on the actually utilized standard cell library.
		set_driving_cell -library uk65lscllmvbbl_120c25_tc -lib_cell XOR2M2WA -pin Z [all_inputs]
                
		## Use four times the load of a mid-sized buffer for all outputs. Note that
		## the following line depends on the actually utilized standard cell
		## library.
		set_load [expr 4 * [load_of uk65lscllmvbbl_120c25_tc/BUFM10W/A]] [all_outputs]

		############################################################################


		## Start compilation.
		compile_ultra
		
		## Save compiled design.
		write -f ddc -h -o $ddcDir/${entity}_compiled.ddc

		## Create some reports.
		check_design                                                                              > $reportsDir/check_design-compiled.rpt
		report_area -hierarchy -nosplit                                                           > $reportsDir/area.rpt
		report_cell -nosplit [all_registers]                                                      > $reportsDir/registers.rpt
		report_reference -nosplit                                                                 > $reportsDir/references.rpt
		report_constraint -nosplit                                                                > $reportsDir/constraints.rpt
		report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins]            > $reportsDir/timing_ss.rpt
		report_timing -from [all_inputs] -to [all_registers -data_pins] -max_paths 10 -path end   > $reportsDir/timing_is.rpt
		report_timing -from [all_registers -clock_pins] -to [all_outputs] -max_paths 10 -path end > $reportsDir/timing_so.rpt
		report_timing -from [all_inputs] -to [all_outputs]                                        > $reportsDir/timing_io.rpt

		## Print the end time to the synthesis run log.
		set endTime "[clock seconds]"
		puts -nonewline $runLog " - End: [clock format $endTime -format ${timeFormat}]"

		## Calculation the duration of the compilation run.
		set duration [expr {$endTime - $startTime}]
		puts $runLog " - Duration: [clock format $duration -gmt 1 -format ${timeFormat}]"
		flush $runLog

		## Create a short summary for the current synthesis run.
		set sum "./$currRunDir/synthesis_summary.txt"

		echo "***** SYNTHESIS RUN SUMMARY *****" > $sum
		echo "" >> $sum
		echo "Entity:            $entity"     >> $sum
		echo "Timing Constraint: ${maxDelay}ns" >> $sum
		echo "" >> $sum
		echo "Starttime:         [clock format ${startTime}]" >> $sum
		echo "Endtime:           [clock format ${endTime}]" >> $sum
		echo "Duration:          [clock format $duration -gmt 1 -format ${timeFormat}]" >> $sum
		echo "" >> $sum;
}

## Calculate the global duration of all synthesis runs.
set globalEndTime "[clock seconds]"
set duration [expr {$globalEndTime - $globalStartTime}]

## Print some information about the required time for all the synthesis runs.
puts $runLog "##"
puts $runLog "## End of Synthesis Runs:        [clock format ${globalEndTime}]"
puts $runLog "## Duration:                     [clock format $duration -gmt 1 -format ${timeFormat}]"
puts $runLog "##"
puts $runLog "## SYNTHESIS RUNS DONE"
puts $runLog "##"
close $runLog
exit

