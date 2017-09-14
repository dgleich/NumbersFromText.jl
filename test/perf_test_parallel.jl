using NumbersFromText
using CSV

data = rand(Int, 32*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, zeros(Int, 0));
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, zeros(Int, 0));
