using NumbersFromText
using CSV

data = rand(Int, 32*1024);
bufsmall = IOBuffer()
foreach(x -> println(bufsmall, x), data)
println("Compiling ...")
seek(bufsmall, 0); @time a, = readarrays!(bufsmall, zeros(Int, 0));
seek(bufsmall, 0); @time a = readarray(bufsmall);
seek(bufsmall, 0); @time a = CSV.read(bufsmall; types =[Int] );
seek(bufsmall, 0); @time a = CSV.read(bufsmall; types =[Float64] );

println("Performance ...")
data = rand(Int, 32*1024*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a = readarray(buf);
seek(buf, 0); @time a = CSV.read(buf; types =[Int] );
seek(buf, 0); @time a = CSV.read(buf; types =[Float64] );


try
  println("Faster parsing")
  seek(bufsmall, 0); a, = readarrays!(bufsmall, zeros(Int, 0); records=NewlineOnly, seperators=Spaces);
  seek(bufsmall, 0); a = readarray(bufsmall; records=NewlineOnly, seperators=Spaces);

  seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0); records=NewlineOnly, seperators=Spaces);
  seek(buf, 0); @time a = readarray(buf; records=NewlineOnly, seperators=Spaces);
catch
  println("Older version without records support?")
end
