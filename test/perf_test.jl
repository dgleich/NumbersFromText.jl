using NumbersFromText
using CSV

data = rand(Int, 32*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
println("Compiling ...")
seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a = readarray(buf);
seek(buf, 0); @time a, = parallel_readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a, = parallel_readarrays!(buf, zeros(Float64, 0));
seek(buf, 0); @time a = CSV.read(buf; types =[Int] );
seek(buf, 0); @time a = CSV.read(buf; types =[Float64] );

println("Peroformance ...")
data = rand(Int, 32*1024*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a = readarray(buf);
seek(buf, 0); @time a, = parallel_readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a, = parallel_readarrays!(buf, zeros(Float64, 0));
seek(buf, 0); @time a = CSV.read(buf; types =[Int] );
seek(buf, 0); @time a = CSV.read(buf; types =[Float64] );
