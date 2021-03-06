About
=====

Synthesis runs of a combinational or sequential design can be accomplished based
on different timing constraints (maximum delay or clock frequency respectively)
and appropriate area and timing reports will be generated (a small Tcl script
will be used for this). Those reports will then be parsed using a Perl script,
generating a single file containing all the area and timing constraints. Based
on the data in that file, a Gnuplot script will then generate a graph, which
gets embedded into a LaTeX container file.

With the provided AT plot generator, AT plots like the one shown in the
following image can easily be created:

![AT plot example](https://github.com/mbgh/at-plot-generator/blob/master/at-plot-sample.png)
