## Set all the graph-related options that can be set with the 'set' command to
## their default values.
reset

################################################################################
## Choose a terminal (output format)

## 1 ... wxt terminal for interactive setup of the AT plot.
## 2 ... epslatex terminal for output AT plot.
term = 1;

## wxt
######
## - Use this for testing since the graph will be shown in a new window.
## - Note that dashed lines (linetype (lt) = 2) will not appear as dashed.
if (term == 1) \
   wxt_font = "SVBasic Manual, 12"; \
   set terminal wxt size 800,500 enhanced font wxt_font persist;

## epslatex
## - Produce a vector output file (PDF) with text elements provided as a LaTex
##   document.
if (term == 2) \
   set terminal epslatex color size 5,3.5; \
   set output 'output.tex';

## png
######
## - Produces raster output file similar to the wxt terminal.
# set terminal pngcairo size 410,250 enhanced font 'Verdana,9'
# set output 'output.png'

## svg
######
## - Produces vector output file similar to the wxt terminal.
## - You may later convert the SVG into a PDF as follows:
##   > rsvg-convert -f pdf -o <OUTPUT.pdf> <INPUT.svg>
# set terminal svg size 410,250 fname 'Verdana, Helvetica, Arial, sans-serif' \
# fsize '9' rounded dashed
# set output 'output.svg'

## postscript (ps)
## - Produces vector output files.
## - Use this if you want to create (LaTeX) reports.
## - If you need a PDF, use the 'epstopdf' tool afterwards.
# set terminal postscript eps size 5.0,4.0 enhanced color font 'Helvetica,30' linewidth 2
# set output 'output.eps'



################################################################################
## Declare some nice colors

## Declare the ETHZ corporate design colors.
eth1  = "#1f407a" ## dark blue
eth2  = "#3c5a0f" ## dark green
eth3  = "#0069b4" ## light blue
eth4  = "#72791c" ## light green
eth5  = "#91056a" ## magenta
eth6  = "#6f6f6e" ## gray
eth7  = "#a8322d" ## red
eth8  = "#007a92" ## cyan
eth9  = "#956013" ## brown
eth10 = "#82be1e" ## lightest green


################################################################################
## Define some line styles for the data to be plotted

## Definition of line styles for the actual data.
pSize  = 3.5 ## Point size
lWidth = 7 ## Line width

set style line 1 lt 1 lc rgb eth3 lw lWidth pt 1 ps pSize
set style line 2 lt 1 lc rgb eth4 lw lWidth pt 6 ps pSize
set style line 3 lt 1 lc rgb eth3 lw lWidth pt 6 ps pSize
set style line 4 lt 1 lc rgb eth4 lw lWidth pt 6 ps pSize

## Definition of line style for ISO lines (constant AT product).
set style line 10 lc rgb '#B9B6B0' lt 2 lw 1.5


################################################################################
## Define the axis and the grid

## Remove border on top and right and set color to gray.
set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror

## Define the grid.
set style line 12 lc rgb '#808080' lt 0 lw 1
set grid back ls 12


################################################################################
## Plot-related settings

## Title of the plot
plotTitle = '' #AT Plot of Various AES-128 Synthesis Runs'

## Axis settings
xAxisMin   =  0.8
xAxisMax   =  1.6
xAxisLabel = 'Clock Period [ns]'

yAxisMin   = 180
yAxisMax   = 280
yAxisLabel = 'Area [kGE]'

## Settings of the key (lengend).
set key top right  ## Location of the key

################################################################################
## Plot-creation

## Set up the plot using the given settings
set title plotTitle
set xlabel xAxisLabel
set ylabel yAxisLabel
set xrange [xAxisMin:xAxisMax]
set yrange [yAxisMin:yAxisMax]

## Add some nice isolines for the constant AT product.
iso40(x) = 40/x
iso60(x) = 60/x
iso80(x) = 80/x
iso100(x) = 100/x
iso120(x) = 120/x
iso150(x) = 150/x
iso160(x) = 160/x
iso180(x) = 180/x
iso200(x) = 200/x
iso210(x) = 210/x
iso220(x) = 220/x
iso225(x) = 225/x
iso240(x) = 240/x
iso250(x) = 250/x
iso300(x) = 300/x
iso400(x) = 400/x
iso500(x) = 500/x
iso600(x) = 600/x
iso700(x) = 700/x
iso800(x) = 800/x

## Create vertical line indicating the fastest synthesis results.
set style line 20 lc rgb 'red'
set style arrow 1 heads size screen 0.008,90 ls 20
set arrow from 0.87,180 to 0.87,280 as 1

## Create a vertical line where we reach 100Gbit/s.
# set arrow from 0.87,180 to 0.87,280 nohead lc rgb 'red'

## Do the actual plotting of the AT data.
plot iso200(x) t '' ls 10, iso225(x) t '' ls 10, iso250(x) t '' ls 10, iso300(x) t '' ls 10, iso400(x) t '' ls 10, \
     'at_data-less.dat' u ($6):($7/1000) t 'GCM-AES-128 - LUT S-box - Top-Down' w p ls 1
     # 'bottom_up/at_data.dat' u ($6):($7/1000) t 'GCM-AES-128 - Canright S-box - Bottom-Up' w p ls 2

################################################################################
