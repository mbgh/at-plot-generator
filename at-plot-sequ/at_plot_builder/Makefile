## Gnuplot binary to be used
GP_BIN = gnuplot44
## Gnuplot script to be used to create the EPS
GP_SRC = gen_at_plot.gp
## Gnuplot output file (EPS)
GP_OUT = output
## EPS to PDf converter
EPS2PDF = epstopdf
## LaTeX file to be used as a container for the image
TEX_SRC = container
## LaTex version to be used
TEX_BIN = pdflatex-2011
## PDF viewer to be used when viewed
PDF_BIN = okular

all: build view

build:
	@echo "***[MAKE]*** Building PDF output ..."
	$(GP_BIN) $(GP_SRC)
	$(EPS2PDF) $(GP_OUT).eps
	$(TEX_BIN) $(TEX_SRC).tex

view:
	@echo "***[MAKE]*** Now viewing PDF output ..."
	$(PDF_BIN) $(TEX_SRC).pdf &

clean:
	@echo "***[MAKE]*** Cleaning directory ..."
	@rm -f $(TEX_SRC).aux $(TEX_SRC).log $(TEX_SRC).tex~ Makefile~
	@rm -f $(GP_SRC)~ $(GP_OUT).tex $(GP_OUT).eps $(GP_OUT).pdf
