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
until you start reading gigabyte sized files in which case the factor of
two becomes appreciable.)

This package provides a number of functions that have been designed to
convert text data into numbers as fast as possible in Julia, with some tradeoffs
designed with an eye towards speed. By default, they will identify numbers
separated with commas, spaces, tabs, or newlines. The types of separators can
be customized as well. Here are some simple examples.

~~~~
M = readmatrix("myfile.txt") # reads a matrix of data
m = readarray("myfile.txt") # just reads a list of Float64s from myfile.txt
m = readarray(Int, "myfile.txt") # just reads a list of Ints from myfile.txt
m = readarray!("myfile.txt", rand(Int, 5)) # read Ints into an existing array, appending to the back
aint, afloat = readarrays("myfile.txt", Int, Float64) # reads alternating Ints and Floats
aint, afloat = readarrays!("myfile.txt", rand(Int,5), rand(Float64,5)) # read into existing arrays
~~~~

The package can help you read more complex data as well. 

Delimiters and Separators
--------------------------

If you have a more complicated file, you can still reuse a lot of our
infrastructure. Essentially, you just need to build your own SimpleTokenizer
based on your own delimiters.

~~~~
toks = SimpleTokenizer(stream, SemicolonsSpacesTabs, Newlines)
readarrays(toks, Int, Float) # todo need to implement
~~~~

**If you are a library designer, there is some small (10%) benefit to being
more precise in your specification of the delimiters.** We designed the
code to be as usable as possible without providing many options and so
we made the call that it would parse commas separated data by default. This
incurs a 10% slowdown. Again, not something to consider unless you have
extremely large text. But something to keep in mind when speed is paramount.

Notes
-----

There are a few quirks

### We only parse Integers and Floats16, 32, 64

There is currently no support for BigFloats. The goal is "NumbersFromText" and
not "arbitrary-data-from-text". See `CSV.jl` for that.

### Why do we need this? Just use binary data for big files.

For a variety of practical reasons, binary data exchange is highly problematic
in terms of the precise specification, data input and output in diverse settings,
etc. See the complexity of HDF5. 
This is a real-world challenge instead of an engineering challenge. Numbers
in text files are superior in many other practical ways involving people without
deep CS expertise. It's worth trying to read them quickly.

### Maximum token length.

We saw a measurable (5-10%) performance increase by restricting the length of
the longest number token identified to 2048. If you wish to increase this,
**TODO** 

### Line breaks and record separators

By default, the parser only considers the _stream_ of tokens and ignores
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

SimpleTokenizer
---------------

The core piece of the library is a simple tokenization library that works 
on files as arrays of characters. This leverages all the optimization of
the Julia team in making arrays fast. 

Parallelism
-----------
There is a prototype for using multiple threads to read in parallel. The
strategy here is simple, and will not yield optimal performance, but it
would work with compressed files. This will be developed on an as-needed
basis. Don't expect more than a factor of two from the parallel reader
regardless of the number of threads used. 
