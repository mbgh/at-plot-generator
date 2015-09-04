#! /usr/bin/perl -w

=head1 NAME

parse_at_data.pl - Script for gathering the data for an AT plot after several
synthesis runs.

=head1 AUTHOR

Michael Muehlberghuber (mbgh@iis.ee.ethz.ch)

=head1 DATE

Created: Wed May 21 15:43:03 CEST 2014

=head1 COPYRIGHT

Copyright (C) 2014 ETHZ Zurich, Integrated Systems Laboratory

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

=head1 SYNOPSIS

./parse_at_data.pl [options]

Options:

   --help        Brief help message
   --man         Full documentation
   --ver         Version information
   --verb        Verbosity level
   --out         File to write the data to
   --useGE       Use gate equivalents for area results
   --ge          Size of one gate equivalent
   -- splitVio   Enable/Disable splitting violating datasets

=head1 OPTIONS

parse_at_data.pl takes the following arguments:

=over 8

=item B<help>

--help

(Optional.) Prints a brief help message and exits.

=item B<man>

--man

(Optional.) Prints the manual page and exits.

=item B<ver>

--ver

(Optional.) Print version information.

=item B<verb>

--verb

(Optional.) Verbosity level to be used when running the script.

=item B<out>

--out

(Optional.) File to write the data to.

=item B<usgeGE>

--useGE

(Optional.) Determine whether to use gate equivalents (GE) for area results or
not.

=item B<ge>

--ge

(Optional.) Size of one gate equivalent (GE).

=item B<splitVio>

--splitVio

(Optional.) Split constraints-violating synthesis runs from
constraints-fulfulling runs with a blank line.

=back

=head1 EXAMPLES

Run the script using its defaults (as defined within the script).

> ./parse_at_data.pl

Provide a specific output file name.

> ./parse_at_data.pl --out=output.dat

Use square micrometer (\mum^2) for the area results.

> ./parse_at_data.pl --useGE=0

Specify the size of one gate equivalent (GE).

> ./parse_at_data.pl --ge=9.3744

Do not split violating/fulfilling data sets with a blank line.

> ./parse_at_data.pl --splitVio=0


=head1 DESCRIPTION

The present script is intended to be used for gathering the results from several
synthesis runs (e.g., using different frequencies or maximum delays) and stores
it in a plain text file. This file may then serve, for instance, as a basis for
drawing a nice AT plot.

=cut

use strict;
use warnings;

use Getopt::Long;   # Processing of command line options
use Pod::Usage;     # Use Plain Old Documentation (POD) to create documentation

################################################################################
################################################################################

## Release version.
my $release = 1.5;

## Default script settings which can be changed using command line options.
my $verb    = 0;                        # Enable verbose output messages
my $out     = "at_data.dat";            # Path to the output file
my $useGE   = 1;                        # Use gate equivalents (GE) or not
my $ge      = 1.44;                     # Size of one gate equivalent (GE)
my $rootDir = ".";                      # Directory containing the subdirectories for the different synthesis runs.
my $area    = "reports/area.rpt";	      # Path to the area reports from wihtin the subdirectories.
my $timing  = "reports/timing_io.rpt";  # Path to the timing reports from wihtin the subdirectories.
my $splitVio = 0;                       # Split constraints violating datasets from non-violating ones using a blank line.
################################################################################27
################################################################################

## Parse provided command line arguments first.
parseCmdLineArgs();

## Get all subdirectories within the root directory.
my @subdirs = split(/\n/,`find $rootDir -maxdepth 1 -type d`);

## Remove the current directory from the subdirectories array (which should
## usually be at its 0-th position).
splice @subdirs, 0, 1;

## Open the output file and create a header.
open (OUT, "> $out") or die "Could not open output file: $out\n";
print OUT "## Author:  $0\n";
print OUT "## Created: " . localtime() . "\n";
print OUT "##\n";
print OUT "## Syntax: <PERIOD_CONSTRAINT> <SETUP_TIME> <CONSTRAINT_MET> <SLACK> <DATA_ARRIVAL_TIME> <PERIOD> <AREA> \n";
print OUT "##\n";
print OUT "##    <PERIOD_CONSTRAINT> ... Period/Max delay constraint set for synthesis\n";
print OUT "##    <SETUP_TIME>        ... Library setup time\n";
print OUT "##    <CONSTRAINT_MET>    ... 1=Constraint met; 0=Constraint not met\n";
print OUT "##    <SLACK>             ... Available slack\n";
print OUT "##    <DATA_ARRIVAL_TIME> ... Data arrival time of the critical path (=<PERIOD_CONSTRAINT>-<SLACK>+<SETUP_TIME>)\n";
print OUT "##    <PERIOD>            ... Actual period with which the circuit will run (=<PERIOD_CONSTRAINT>-<SLACK>)\n";
if ( $useGE ) {
	print OUT "##    <AREA>              ... Resulting area in gate equivalents\n";
} else {
	print OUT "##    <AREA>              ... Resulting area in square micrometer\n";
}
print OUT "##\n";

foreach my $subdir (@subdirs) {
	print "Investigating directory:         $subdir \n" if $verb;

	##############################################################################
	## Start by parsing some timinig-specific information from the timing report.

	my $requTime;
	my $slack;
	my $dataArrTime;
	my $periodConstr;
	my $period;

	print "Trying to parse the data required time (frequency/max delay) from: $subdir/$timing\n" if $verb;

	## Check if timing report actually exists.
	unless ( -e "$subdir/$timing" ) {
		print "Could not find the timing report: $subdir/$timing\n";
		next;
  }

	## Determine the actual period constraint and the library setup time (if
	## available).
	my $prevLine = "";
  ## Note that we set the setup time per default to zero as it could be that we
  ## parse a fully combinational result (from the in-to-out timing reports),
  ## where we have no setup time at all.
	my $setupTime = 0;
	open (IN, "< $subdir/$timing") or die "Could not open file: $subdir/$timing\n";
	while (<IN>) {
		if ($_ =~ m/^\s*data required time\s*(-?\d*\.\d*)\s*/) {
			$requTime = $1;
			print "==> Data required time: $requTime \n" if $verb;
			$periodConstr = $requTime;

			## Check if there was a library setup time.
			if ($prevLine =~ m/^\s*library setup time\s*(-?\d*\.\d*)\s*(-?\d*\.\d*)\s*/) {
				$setupTime = $1;
				print "==> Library setup time: $setupTime\n" if $verb;

				## Since we have a library setup time, the original period constraind is
				## the data required time - the library setup time.
				$periodConstr = $periodConstr - $setupTime;
			}

			## Print two decimal places and two places in front of the comma into the
			## file (5-2(decimal)-1(decimal place) = 2).
			printf OUT "%5.2f", $periodConstr;
			printf OUT "  %5.2f", $setupTime;

			last; ## Stop searching for the slack in the timing report.
		}
		## Store previous line in order to determine a potential library setup time
		## once the data required time has been found.
		$prevLine = $_;
	}

	print "Trying to parse the slack from: $subdir/$timing\n" if $verb;

	## Check if timing report actually exists.
	unless ( -e "$subdir/$timing" ) {
		print "Could not find the timing report: $subdir/$timing\n";
		next;
  }

	## Search for the slack in the timing report.
	open (IN, "< $subdir/$timing") or die "Could not open file: $subdir/$timing\n";
	while (<IN>) {
		## The following regex will parse the slack from the timing report. It
		## should match file rows like the followings (note that there are several
		## "non-capturing groups" in there, which are initiated with a "?:").
		##
		## SAMPLE 1:   slack (MET)                                         0.53
		## SAMPLE 2:   slack (VIOLATED: increase signficant digits)        0.00
		## SAMPLE 3:   slack (VIOLATED)                                 -0.6596
		if ($_ =~ m/^\s*slack\s*\((\w*)(?:\)|:(?:\w*\s*)*\))\s*(-?\d*\.\d*)\s*/) {
			$slack = $2;
			print "==> Slack: $slack ($1)\n" if $verb;
			if ( $1 eq "MET" ) {
				print OUT "  1";
			} else {
				print OUT "  0";
			}
			printf OUT "  %5.2f", $slack;
			last; ## Stop searching for the slack in the timing report.
		}
	}
	$dataArrTime = $requTime-$slack;
	$period = $periodConstr-$slack;

	printf OUT " %6.2f", $dataArrTime;
	printf OUT " %6.2f", $period;

	##############################################################################
	## Go on by parsing the area information.

	print "Trying to parse the area from:   $subdir/$area\n" if $verb;

	## Check if area report actually exists.
	unless ( -e "$subdir/$area" ) {
		print "Could not find the area report: $subdir/$area\n";
		next;
  }

	## Search for the total cell area in the area report.
	open (IN, "< $subdir/$area") or die "Could not open file: $subdir/$area\n";
	while (<IN>) {
		if ($_ =~ m/^Total cell area:\s*(\d*\.\d*)\s*/) {
			print "==> Total cell area: $1\n" if $verb;
			if ( $useGE ) {
				## Print area in gate equivalents (GE) to output file.
				printf  OUT "  %8.2f\n", $1/$ge;
			} else {
				## Print area in \mum^2 to output file.
				printf OUT "  %8.2f\n", $1;
			}
			last; ## Stop searching for the total area in the area report.
		}
	}

}

## Close the opened files.
close IN;
close OUT;

## Finally sort the file rows based on the first "column" (should contain the
## period/max delay).
sortFileRows($out);



################################################################################
## Some helper functions.

=head2 write2Shell

Print some text to the shell output.

=cut

sub write2Shell {
  system("echo", "-n", "***", $_[0]);
}

=head2 printSettings

Print the current settings of the script.

=cut

sub printSettings {
	write2Shell("***** COMPILE SCRIPT SETTINGS ****************************************\n");
	write2Shell("Verbose Mode:        $verb\n");
	write2Shell("Output file::        $out\n");
	write2Shell("Root Directory:      $rootDir\n");
	write2Shell("Area Reports Path:   $area\n");
	write2Shell("Timing Reports Path: $timing\n");
	write2Shell("**********************************************************************\n");
}


=head2 parseCmdLineArgs

Parse the arguments specified upon the command line.

=cut

sub parseCmdLineArgs {

	my $help = 0;  # Display help overview
	my $man  = 0;  # Display manual page for script
	my $ver  = 0;  # Display the version number

	## Parse command line options (if provided, otherwise keep their defaults) and
	## print usage if there is a syntax error, or if usage was explicitly request.
	GetOptions (
    'help|?'        => \$help,
    'man'           => \$man,
    'verb:i'        => \$verb,
    'out:s'         => \$out,
		'useGE:i'       => \$useGE,
		'ge:f'          => \$ge,
		'splitVio:i'    => \$splitVio,
    'ver|v|version' => \$ver) or pod2usage(2);
	pod2usage(1) if $help;
	pod2usage(-verbose => 2) if $man;

	printSettings() if $verb;

	if ( $ver ) {
		printf "***** parse_at_data.pl release version = %3.1f\n", $release;
		## Exit script with exit code 0 in order to tell a potentially calling shell
		## that this is an intended exit.
		exit 0;
	}
}

=head2 sortFileRows

Sorts the rows of a file based on the number in the first "column".

=head3 Arguments

=over 15

=item C<$_[0]>

Path to the file to be sorted.

=back

=cut

sub sortFileRows {
	print "Trying to sort rows of file: $_[0]\n" if $verb;

	my $inpFile   = $_[0];   # Provided input file path.
	my %inp;                 # Hash holding all input rows in memory (for sorting).

	## Read all data-containing rows from input file into memory.
	my $hdrRowCnt = 0;
	my @header;
	open(IN, "<$inpFile") or die "Can't open input file: $!";
	while ( <IN> ){

		## Look for data-containing rows.
		if ( $_ =~ m/\s*(\d*\.\d*)\s*(-?\d*\.\d*)\s*(\d)\s*(-?\d*\.\d*)\s*(\d*\.\d*)\s*(\d*\.\d*)\s*/) {
			$inp{$1} = $_;
		} else {
			## If the row syntax does not fit the data format, we assume it to be a
			## row belonging to the file header.
			push(@header, $_);
			$hdrRowCnt++;
		}
	}
	close IN;

	## Open clean output file and write header rows first.
	open(OUT, "> $inpFile") or die "Can't open output file: $!";
	foreach (@header) { print OUT $_; }

	## Write rows into output file sorted according to the first "column".
	my $prevSlack = 0;
	foreach my $row (sort values %inp) {
		## Check whether data set should be split by an empty line between
		## periods/max delays fulfilling the constraint and those violating the
		## constraint.
		if ( $splitVio ) {
			if ( $row =~ m/\s*(\d*\.\d*)\s*(-?\d*\.\d*)\s*(\d)\s*(-?\d*\.\d*)\s*(\d*\.\d*)\s*(\d*\.\d*)\s*/) {
				## Add a blank line between constraints violating runs and
				## constraints-fulfilling synthesis runs.
				if ( $prevSlack < 0 and $4 >= 0 ) {
					print OUT "\n";
				}
				print OUT "$row";
				$prevSlack = $4;
			}
		} else {
			print OUT "$row";
		}
	}
}
