

function readarray!(io, a, maxbuf=2048)
  T = eltype(a)
  toks = SpaceTokenizer(io, maxbuf)
  #@code_warntype step!(toks)
  while true
      curlen = step!(toks)
      if curlen <= 0
          break
      end
      push!(a, myparse(T, toks.buf, 1, curlen))
  end
  return a
end

readarray(io; maxbuf=2048) = readarray!(io, zeros(0), maxbuf)
readarray(::Type{T}, io; maxbuf=2048) where {T} = readarray!(io, zeros(T,0), maxbuf)
