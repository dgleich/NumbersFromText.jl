

const _default_maxbuf_size = 2048
function readarray!(io, a; maxbuf=_default_maxbuf_size)
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

# Given a filename, refer to the type with an IO
function readarray!(filename::AbstractString, a; kwargs...)
  open(filename, "r") do fh
    return readarray!(fh, a; kwargs...)
  end
end

readarray(io; kwargs...) = readarray(Float64, io; kwargs...)
readarray(::Type{T}, io; kwargs...) where {T <: ParsableNumbers} =
  readarray!(io, zeros(T,0); kwargs...)

# Everything with filenames refers to the types of io
readarray(filename::AbstractString; kwargs...) =
  readarray(Float64, filename; kwargs...)

function readarray(::Type{T}, filename::AbstractString; kwargs...) where {T <: ParsableNumbers}
  open(filename, "r") do fh
    return readarray(T, fh; kwargs...)
  end
end

"""
Documentation
"""
:readarrays, :readarrays!


function readarrays!(io, as...; maxbuf=_default_maxbuf_size)
  Ts = map(eltype, as)
  N = length(Ts)
  toks = SpaceTokenizer(io, maxbuf)
  cur = 1
  while true
    curlen = step!(toks)
    if curlen <= 0
      break
    end
    push!(as[cur], myparse(Ts[cur], toks.buf, 1, curlen))
    cur += 1
    if cur > N
      cur = 1
    end
  end
  as
end

function readarrays!(filename::AbstractString, as...; kwargs...)
  open(filename, "r") do fh
    return readarrays!(fh, as...; kwargs...)
  end
end

readarrays(io, Ts...; kwargs...) =
  readarrays!(io, map(T -> zeros(T,0), Ts)...; kwargs...)

function readarrays(filename::AbstractString, as...; kwargs...)
  open(filename, "r") do fh
    return readarrays(fh, as...; kwargs...)
  end
end
