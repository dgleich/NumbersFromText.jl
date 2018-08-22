using NumbersFromText
using Test

dir = joinpath(dirname(@__FILE__),"test_files/")

@testset "Examples" begin
  @testset "SimpleTokenizer" begin
    io = IOBuffer(b"1 56,3.0\t2.0\n4 ")
    toks = SimpleTokenizer(io)
    @test 1 == NumbersFromText.next(Int, toks)
    @test 56 == NumbersFromText.next(Int, toks)
    curlen = NumbersFromText.step!(toks) # return the length of the next token
    @test 3 == curlen
    @test 3.0 == parse(Float64, String(toks.buf[1:curlen]))
    @test 2.0 == NumbersFromText.next(Float64, toks) # this is a simple way to do that!
    # the next line reads until a new token, but checks for record separators
    @test true == NumbersFromText.find_record_seperator(toks)
    @test 4.0 == NumbersFromText.next(Float64, toks) # you can parse Ints as Floats
    @test false == NumbersFromText.end_of_stream(toks) # not at EOS yet, because of space
    @test 0.0 == NumbersFromText.next(Float64, toks) # if you parse too far, you get 0
    # a better strategy is to use curlen and step!, because curlen == -1 if
    # you are at the end of the stream.
    @test -1 == NumbersFromText.step!(toks)
    @test true == NumbersFromText.end_of_stream(toks)

    io = IOBuffer(b"1\t56\t3.0\n2.0\n4")
    # separators are spaces or tabs, records are newlines.
    toks = SimpleTokenizer(io, SpacesTabs, Newlines)
    @test false == NumbersFromText.find_record_seperator(toks)
    @test 1 == NumbersFromText.next(Int, toks)
    @test false == NumbersFromText.find_record_seperator(toks)
    @test 56 == NumbersFromText.next(Int, toks)
    @test false == NumbersFromText.find_record_seperator(toks)
    @test 3.0 ==  NumbersFromText.next(Float64, toks)
    @test true == NumbersFromText.find_record_seperator(toks)
    @test 2.0 == NumbersFromText.next(Float64, toks)
  end

end

@testset "SimpleTokenizer" begin
  begin
    buf = IOBuffer(b"5\n6\n")
    toks = SimpleTokenizer(buf, Spaces, Newlines)
    curlen = NumbersFromText.step!(toks)
    @test String(toks.buf[1:curlen]) == "5"
  end
end

@testset "myparse" begin
  @testset "Integers" begin
    @test 1234 == NumbersFromText.myparse(Int64, b"+1234")
    @test -1234 == NumbersFromText.myparse(Int64, b"-1234")
    @test 1234 == NumbersFromText.myparse(Int32, b"+1234")
    @test -1234 == NumbersFromText.myparse(Int32, b"-1234")
    @test 1234 == NumbersFromText.myparse(Int16, b"+1234")
    @test -1234 == NumbersFromText.myparse(Int16, b"-1234")

    @test_throws ArgumentError NumbersFromText.myparse(Int16, b"1234567")
    @test_throws ArgumentError NumbersFromText.myparse(Int32, b"123456790123456")
    @test_throws ArgumentError NumbersFromText.myparse(Int64, b"12345679012345678901234567890")

    @test_throws ArgumentError NumbersFromText.myparse(Int64, b" 1234 ")
    @test_throws ArgumentError NumbersFromText.myparse(Int64, b" 1234")
    @test_throws ArgumentError NumbersFromText.myparse(Int64, b"1234 ")

    @test_throws ArgumentError NumbersFromText.myparse(UInt64, b"-1234")
  end

  @testset "bool" begin
    @test false == NumbersFromText.myparse(Bool, b"0")
    @test true == NumbersFromText.myparse(Bool, b"1")
  end

  @testset "Floats" begin
    @test eps(Float64)== NumbersFromText.myparse(Float64, b"2.220446049250313e-16")
    @test nextfloat(0.0)== NumbersFromText.myparse(Float64, b"5.0e-324")
    @test eps(Float32) ==NumbersFromText.myparse(Float32, b"1.1920928955078125e-7")
    @test prevfloat(Inf) == NumbersFromText.myparse(Float64, b"1.7976931348623157e308")
    @test floatmin(Float64) == NumbersFromText.myparse(Float64, b"2.2250738585072014e-308")
    @test Inf == NumbersFromText.myparse(Float64, b"Inf")
    @test Inf == NumbersFromText.myparse(Float64, b"+Infinity")
    @test -Inf == NumbersFromText.myparse(Float64, b"-inf")
    @test -Inf == NumbersFromText.myparse(Float64, b"-infinity")
    @test isnan(NumbersFromText.myparse(Float64, b"Nan"))
    @test isnan( NumbersFromText.myparse(Float64, b"nan"))
    @test isnan(NumbersFromText.myparse(Float64, b"NaN"))
    @test isnan(NumbersFromText.myparse(Float64, b"NaN(5)"))
    @test isnan(NumbersFromText.myparse(Float64, b"-NaN(5)"))
    @test isnan(NumbersFromText.myparse(Float64, b"+NaN(5)"))
    @test 0.3366599143757278 == NumbersFromText.myparse(Float64, b"0.3366599143757278")
    @test -0.5900190058373408 == NumbersFromText.myparse(Float64, b"-0.5900190058373408")
    @test -0.19043382659933977 == NumbersFromText.myparse(Float64, b"-0.19043382659933977")
    @test -0.16827871837317745 == NumbersFromText.myparse(Float64, b"-0.16827871837317745")

    for i=1:10
      x = randn()
      buf = IOBuffer()
      print(buf, x)
      s = readavailable(seek(buf, 0))
      @test x == NumbersFromText.myparse(Float64, s)
    end
  end
end

array_int_float_filename = joinpath(dir, "arrays_int_float.txt")
array_int_float_contents = Any[
Vector{Int}([1 , 2 , 3 , 4 , 5 , 6 , -1, -2]),
Vector{Float64}([3.0, 4.0, 5.0, 6.0, -1.0, 1.0e18, -1.0e18, 1.23412341234123512341234e-000008])
]

@testset "readarray" begin
  data = [1/3*ones(500); pi*ones(500); nextfloat(0.0)*ones(500)]
  buf = IOBuffer()
  for i in data
    print(buf, i)
    print(buf, "  ")
  end
  seek(buf, 0) # reset buffer
  a = readarray!(buf, zeros(0))
  @test a == data

  data = Array{UInt8}("1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  @test_throws ArgumentError readarray(buf)
  seek(buf,0)
  @test_throws ArgumentError readarray(buf; maxbuf=2048)
  seek(buf,0)
  a = readarray(buf; maxbuf=2052)
  @test a == [1.0,2.0]

  data = [1/3*ones(500); pi*ones(500); nextfloat(0.0)*ones(500)]
  buf = IOBuffer()
  for i in data
    print(buf, i)
    print(buf, " ")
  end
  seek(buf, 0) # reset buffer
  a = readarray!(buf, zeros(0))
  @test a == data

  data = [1/3*ones(500); pi*ones(500); nextfloat(0.0)*ones(500)]
  buf = IOBuffer()
  for i in data
    print(buf, i)
    print(buf, "  ")
  end
  seek(buf, 0) # reset buffer
  a = readarray!(buf, zeros(0))
  @test a == data

  data = ones(Int, 500)
  buf = IOBuffer()
  foreach(x -> println(buf, x), data)
  seek(buf, 0)
  a = readarray!(buf, zeros(Int, 0))
  @test a == data
  seek(buf, 0)
  a = readarray(Int, buf)

  a = readarray(array_int_float_filename)
  @test a == vec(hcat(array_int_float_contents...)')

  @test readarray(IOBuffer(b"5,6")) == [5.0,6.0]

  @test readarray(IOBuffer(b"5\n6\n"); seperators=Spaces, records=Newlines) == [5.0, 6.0]
end

@testset "readarrays" begin
  data1 = 1/3*ones(500)
  data2 = ones(Int, 500)
  buf = IOBuffer()
  for i in eachindex(data1)
    print(buf, data1[i] )
    print(buf, "  ")
    print(buf, data2[i] )
    print(buf, "  ")
  end
  seek(buf, 0) # reset buffer
  a1, a2 = readarrays!(buf, zeros(0), zeros(Int, 0))
  @test a1 == data1
  @test a2 == data2

  seek(buf, 0) # reset buffer
  a1, a2 = readarrays(buf, Float64, Int)
  @test a1 == data1
  @test a2 == data2


  data = Array{UInt8}("1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  @test_throws ArgumentError readarrays(buf, Float64)
  seek(buf,0)
  @test_throws ArgumentError readarrays(buf, Float64; maxbuf=2048)
  seek(buf,0)
  a, = readarrays(buf, Float64; maxbuf=2052)
  @test a == [1.0,2.0]

  a1,a2 = readarrays(array_int_float_filename, Int, Float64)
  @test Any[a1,a2] == array_int_float_contents

end


@testset "readmatrix" begin
  using DelimitedFiles
  data = randn(3,2)
  buf = IOBuffer()
  writedlm(buf, data, "\t ")
  seek(buf, 0) # reset
  a = readmatrix(buf)
  @test a == data

  buf = IOBuffer("1.0")
  a = readmatrix(buf)
  @test a == ones(1,1)

  data = Array{UInt8}("1.0"*("0"^2048))
  buf = IOBuffer(data)
  @test_throws ArgumentError a = readmatrix(buf)


  data = Array{UInt8}("1.0 1.0\n1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  a = readmatrix(buf; maxbuf = 2052)
  @test a == [1.0 1.0; 1.0 2.0]

  data = Array{UInt8}("1.0 1.0\n1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  a = readmatrix(buf; maxbuf = 2052, transpose=false)
  @test a == [1.0 1.0; 1.0 2.0]'

  a = readmatrix(joinpath(array_int_float_filename))
  @test a == hcat(array_int_float_contents...)
end


@testset "partition_buffer" begin
  data = collect(1:500)
  buf = IOBuffer()
  foreach(x -> println(buf, x), data)
  seek(buf, 0)
  dataarray = take!(buf)

  maxparts = 49
  bufs = allocate_buffers(maxparts)

  for nparts=1:maxparts
    n = partition_buffer(dataarray, length(dataarray), nparts, bufs, UInt8('\n'))
    newdata = Vector{UInt8}()
    for i=1:n
      push!(newdata, read(bufs[i])...)
    end
    @test dataarray == newdata
  end

end


@testset "parallel_readarrays" begin
  #=
  data = rand(Int, 32*1024*1024)
  buf = IOBuffer()
  foreach(x -> println(buf, x), data)
  seek(buf, 0)
  a, = readarrays!(Val{true}, buf, zeros(Int, 0))
  @test a == data
  =#
end
