using NumbersFromText

data = rand(Int, 1024*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
@time 1 # get @time compiled
a, = readarrays!(Val{true}, buf, zeros(Int, 0), nthreads=2);
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, zeros(Int, 0), nthreads=2);
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, zeros(Int, 0), nthreads=2);

data = rand(Int, 4*1024*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, sizehint!(zeros(Int, 0), 6*2^20), nthreads=2);
Profile.clear_malloc_data()
seek(buf, 0); @time a, = readarrays!(Val{true}, buf, sizehint!(zeros(Int, 0), 6*2^20), nthreads=2);
