# NumbersFromText

[![Build Status](https://travis-ci.org/dgleich/NumbersFromText.jl.svg?branch=master)](https://travis-ci.org/dgleich/NumbersFromText.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/dgleich/NumbersFromText.jl?svg=true)](https://ci.appveyor.com/project/dgleich/NumbersFromText-jl)
[![CodeCov](https://codecov.io/gh/dgleich/NumbersFromText.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dgleich/NumbersFromText.jl)

For some reason, it seems to take a long to convert text information into
numbers in Julia. Functions for this purpose are `readdlm` and `CSV.jl`. These
packages are great if you need to read _complex_ data from files. However, there
are many use-cases where the only information in the file is a set of
ASCII formatted numbers. For these files, we can read them much faster.
This can be twice as fast! (Note that this speed difference doesn't matter
until you start reading gigabyte sized files.)

This package provides a number of functions that have been designed to
convert text data into numbers as fast I could in Julia.

~~~~
M = readmatrix("myfile.txt") # reads a matrix of data
m = readarray("myfile.txt") # just reads a list of Float64s from myfile.txt
aint, afloat = readarrays("myfile.txt", Int, Float64)
~~~~

Currently, the parser only considers the _stream_ of tokens and ignores
all line-breaks. (This is just like `fscanf` in C).
Hence, the following files are equivalent to
`readarray`, and `readarrays`

~~~~
File 1:
1 2.0
3 4.0
~~~~

~~~~
File 2:
1 2.0 3 4.0
~~~~

The only exception is `readmatrix`, which infers the number of columns
from the first line of the file.
