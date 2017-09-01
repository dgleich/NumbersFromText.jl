using NumbersFromText
using Base.Test

@testset "SpaceTokenizer" begin

end

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
end

#=
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
  @test_throws ArgumentError a = readarray(buf)


  data = convert(Array{UInt8}, "1.0 1.0\n1.0"*("0"^2048)*"      2.0")
  buf = IOBuffer(data)
  a = readmatrix(buf; maxbuf = 2052)
  @test a == [1.0 1.0; 1.0 2.0]
end
=#
