const _default_maxbuf_size = 2048

"""
Documentation
"""
:readarrays, :readarrays!

@generated function readarrays!(rval::Type{Val{T}}, toks::SpaceTokenizer, as...) where {T}
  N = length(as)
  Ts = map(eltype, as)

  #@show rval

  # the basic loop is simple, we just keep reading!
  expr = quote
    while true
    end
  end

  if T
    push!(expr.args,:(return as))
  else
    push!(expr.args,:(return))
  end

  for i=1:length(as)
    expr_read = quote
        curlen = step!(toks)
        if curlen <= 0
          break
        end
        push!(as[$i], myparse($(Ts[i]), toks.buf, 1, curlen))
    end
    push!(expr.args[2].args[2].args, expr_read)
  end
  expr_record_check = quote
    if find_record_seperator(toks) == false
      throw(ArgumentError("Invalid record format"))
    end
  end
  push!(expr.args[2].args[2].args, expr_record_check)
  #@show expr
  return expr
end

function readarrays!(toks::SpaceTokenizer, as...)
  return readarrays!(Val{true}, toks, as...)
end

function readarrays!(io, as...; maxbuf=_default_maxbuf_size)
  toks = SpaceTokenizer(io, maxbuf)
  return readarrays!(toks, as...)
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

"""
"""
:readarray, :readarray!

readarray!(io, a; kwargs...) = readarrays!(io, a; kwargs...)[1]

readarray(::Type{T}, io; kwargs...) where {T <: ParsableNumbers} =
  readarray!(io, zeros(T,0); kwargs...)
readarray(io; kwargs...) = readarray(Float64, io; kwargs...)

#=
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
=#


"""
Documentation
"""
:readmatrix

function readmatrix(::Type{T}, io; transpose::Bool=true, kwargs...) where {T <: ParsableNumbers}
  firstline = readline(io) # read the first line
  a = zeros(T, 0)
  readarray!(IOBuffer(firstline), a; kwargs...)
  ncols = length(a)
  readarray!(io, a; kwargs...)
  nrows, nrem = divrem(length(a),ncols)
  if nrem != 0
    throw(ArgumentError("first line had $(ncols) entries," *
      " but overall there were $(length(a)) entries for " *
      "$(nrows) rows and $(nrem) left"))
  else
    if transpose
      return Base.transpose(reshape(a, ncols, nrows))
    else
      return reshape(a, ncols, nrows)
    end
  end
end
readmatrix(io; kwargs...) = readmatrix(Float64, io; kwargs...)

function readmatrix(::Type{T}, filename::AbstractString; kwargs...) where {T <: ParsableNumbers}
  open(filename, "r") do fh
    return readmatrix(T, fh; kwargs...)
  end
end
readmatrix(filename::AbstractString; kwargs...) = readmatrix(Float64, filename; kwargs...)
