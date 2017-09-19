using NumbersFromText
using CSV

data = rand(Int, 32*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
println("Compiling ...")
seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0));
seek(buf, 0); @time a = readarray(buf);
seek(buf, 0); @time a = CSV.read(buf; types =[Int] );
seek(buf, 0); @time a = CSV.read(buf; types =[Float64] );

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
  bufsmall = IOBuffer();
  foreach(x -> println(bufsmall, x), rand(Int, 32*1024));
  seek(bufsmall, 0); a, = readarrays!(bufsmall, zeros(Int, 0); records=Newlines, seperators=Spaces);
  seek(bufsmall, 0); a = readarray(bufsmall; records=Newlines, seperators=Spaces);

  seek(buf, 0); @time a, = readarrays!(buf, zeros(Int, 0); records=Newlines, seperators=Spaces);
  seek(buf, 0); @time a = readarray(buf; records=Newlines, seperators=Spaces);
catch
  println("Older version without records support?")
end
