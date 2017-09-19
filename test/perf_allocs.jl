using NumbersFromText

data = rand(Int, 1024*1024);
buf = IOBuffer()
foreach(x -> println(buf, x), data)
function multiple_toks(io, a::Vector{Int}, n::Integer, k::Integer)
  tok = NumbersFromText.SpaceTokenizer(io)

  for i=1:n
    NumbersFromText.reset(tok)
    for j=1:k
      push!(a, next(Int, tok))
    end
  end
  a
end
seek(buf, 0); @time a = multiple_toks(buf, zeros(Int, 0), 1, 1);
seek(buf, 0); @time a = multiple_toks(buf, zeros(Int, 0), 5, 100);
seek(buf, 0); @time a = multiple_toks(buf, zeros(Int, 0), 5, 200);
seek(buf, 0); @time a = multiple_toks(buf, zeros(Int, 0), 10, 100);
seek(buf, 0); @time a = multiple_toks(buf, zeros(Int, 0), 10, 200);

# This shows we aren't allocating many vectors in parallel.jl


##

function multiple_readarrays(io, a::Vector{Int}, n::Integer)
  tok = NumbersFromText.SpaceTokenizer(io)

  for i=1:n
    NumbersFromText.reset(tok)
    readarrays!(Val{false}, tok, a)
  end
  a
end

a = sizehint!(zeros(Int, 0), 10^7)
seek(buf, 0); @time a = multiple_readarrays(buf, a, 25);
seek(buf, 0); @time a = multiple_readarrays(buf, a, 1);
seek(buf, 0); @time a = multiple_readarrays(buf, a, 2);
seek(buf, 0); @time a = multiple_readarrays(buf, a, 4);
seek(buf, 0); @time a = multiple_readarrays(buf, a, 8);
seek(buf, 0); @time a = multiple_readarrays(buf, a, 16);

function multiple_readarrays2(io, a::Vector{Int}, n::Integer)
  tok = NumbersFromText.SpaceTokenizer(io)
  a2 = sizehint!(zeros(Int,0),10^7)
  as = [a, a2]
  myt = tuple(as...)
  for i=1:n
    NumbersFromText.reset(tok)
    readarrays!(Val{false}, tok, myt)
  end
  a
end

a = sizehint!(zeros(Int, 0), 10^7)
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 25);
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 1);
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 2);
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 4);
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 8);
seek(buf, 0); @time a = multiple_readarrays2(buf, a, 16);

