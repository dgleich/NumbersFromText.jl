using NumbersFromText
using Base.Test

dir = joinpath(dirname(@__FILE__),"test_files/")

@testset "SpaceTokenizer" begin

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

  data = convert(Array{UInt8}, "1.0"*("0"^2048)*"      2.0")
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


  data = convert(Array{UInt8}, "1.0"*("0"^2048)*"      2.0")
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
  data = randn(3,2)
  buf = IOBuffer()
  writedlm(buf, data, "\t ")
  seek(buf, 0) # reset
  a = readmatrix(buf)
  @test a == data

  buf = IOBuffer("1.0")
  a = readmatrix(buf)
  @test a == ones(1,1)

  data = convert(Array{UInt8}, "1.0"*("0"^2048))
  buf = IOBuffer(data)
  @test_throws ArgumentError a = readmatrix(buf)


  data = convert(Array{UInt8}, "1.0 1.0\n1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  a = readmatrix(buf; maxbuf = 2052)
  @test a == [1.0 1.0; 1.0 2.0]

  data = convert(Array{UInt8}, "1.0 1.0\n1.0"*("0"^2048)*"      2.0")
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
