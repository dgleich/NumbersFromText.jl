using NumbersFromText

data = rand(Int, 32*1024*1024)
buf = IOBuffer()
foreach(x -> println(buf, x), data)
seek(buf, 0)
@time a, = readarrays!(buf, zeros(Int, 0))
