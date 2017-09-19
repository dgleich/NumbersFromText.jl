
include("delims.jl")

const _smallbuf_size = 256
#@show _smallbuf_size

""" SimpleTokenizer is a type to do fast tokenization of an input IO. """
mutable struct SimpleTokenizer{T,S,R}
    io::T
    buf::Array{UInt8,1}
    smallbuf::Array{UInt8,1}
    smallbufpos::Int
    smallbuflen::Int


    SimpleTokenizer(stream::T) where {T <: IO} = SimpleTokenizer(stream, CommasSpacesTabsNewlines)
    SimpleTokenizer(stream::T, maxbuf::Int) where {T <: IO} = SimpleTokenizer(
          stream, CommasSpacesTabsNewlines, CommasSpacesTabsNewlines, maxbuf)
    SimpleTokenizer(stream::T, ::Type{S}) where {
          T <: IO, S <: DelimiterCodes} = SimpleTokenizer(stream, S, S)
    SimpleTokenizer(stream::T, ::Type{S}, ::Type{R}) where {
          T <: IO, S <: DelimiterCodes, R <: DelimiterCodes} = SimpleTokenizer(
          stream, S, R, 2^10)

    SimpleTokenizer(stream::T, ::Type{S}, ::Type{R}, maxbuf::Int) where {
      T <: IO, S <: DelimiterCodes, R <: DelimiterCodes} = begin
        smallbuf = Array{UInt8,1}(_smallbuf_size)
        smallbuflen = readbytes!(stream, smallbuf, _smallbuf_size)
        new{T,S,R}(
          stream, Array{UInt8,1}(maxbuf), smallbuf, 1, smallbuflen)
    end
end

"""
This could be executed after the underyling IOBuffer has been
reset.
"""
function reset(itr::SimpleTokenizer)
  itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
  itr.smallbufpos = 1
end

@inline function _read_spaces(itr::SimpleTokenizer{T,S,R}) where {T,S <: DelimiterCodes,R <: DelimiterCodes}
    #@show String(smallbuf), smallbufpos, smallbuflen
    @inbounds while itr.smallbuflen > 0
        #if isspacecode(itr.smallbuf[itr.smallbufpos])
        #if match(SpacesTabsNewlines, itr.smallbuf[itr.smallbufpos])
        if match(S, itr.smallbuf[itr.smallbufpos])
            itr.smallbufpos += 1 # move the position
            if itr.smallbufpos > itr.smallbuflen
                # need to refill the buffer
                itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
                itr.smallbufpos = 1
            end
        else
            break
        end
    end
    return itr.smallbuflen > 0
end

#@inline _is_record_code(b::UInt8, itr::SimpleTokenizer{T,S,R}) = match(::Val{S}, b)
#@inline _is_separator_code(b::UInt8, itr::SimpleTokenizer{T,S,R}) = match(::Val{S}, b)

@inline _is_delim(S,R,b::UInt8) = match(S,b) || match(R,b)

@inline function _buffer_nonspaces(itr::SimpleTokenizer{T,S,R}) where {T,S,R <: DelimiterCodes}
    curbuf = 0
    @inbounds while itr.smallbuflen > 0
        #if isspacecode(itr.smallbuf[itr.smallbufpos])
        #if match(S, itr.smallbuf[itr.smallbufpos]) || match(R, itr.smallbuf[itr.smallbufpos])
        #if match(SpacesTabsNewlines, itr.smallbuf[itr.smallbufpos])
        if _is_delim(S,R,itr.smallbuf[itr.smallbufpos])
            break
        else
            curbuf += 1
            if curbuf > length(itr.buf)
                # 2017-09-19: Tried to have growing buffers, but it
                # caused a 20-30% slowdown in the parsing. Crazy! I'll
                # live with fixed sizes...
                #resize!(itr.buf, 2*length(itr.buf))
                throw(ArgumentError("tokensize exceeded buffer"))
            end
            itr.buf[curbuf] = itr.smallbuf[itr.smallbufpos] # save the current value
            itr.smallbufpos += 1
            if itr.smallbufpos > itr.smallbuflen
                # need to refill the buffer
                itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
                itr.smallbufpos = 1
            end
        end
    end
    return curbuf
end

@inline function find_record_seperator(itr::SimpleTokenizer{T,S,R}) where {T,S,R <: DelimiterCodes}
  @inbounds while itr.smallbuflen > 0
      # it's important we check for the record sep first.
      if match(R, itr.smallbuf[itr.smallbufpos])
          itr.smallbufpos += 1 # move the position
          if itr.smallbufpos > itr.smallbuflen
              # need to refill the buffer
              itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
              itr.smallbufpos = 1
          end
          return true
      elseif match(S, itr.smallbuf[itr.smallbufpos])
          itr.smallbufpos += 1 # move the position
          if itr.smallbufpos > itr.smallbuflen
              # need to refill the buffer
              itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
              itr.smallbufpos = 1
          end
      else
          return false
      end
  end
  return itr.smallbuflen == 0 # We have an implied record sep at the end of file.
end

@inline function step!(itr::SimpleTokenizer)
    # The step function has to read through spaces
    # then store non-spaces into buf
    # Then read through the rest of the spaces
    if _read_spaces(itr)
        return _buffer_nonspaces(itr)
    else
        return -1
    end
end

@inline function end_of_stream(itr::SimpleTokenizer)
    return itr.smallbuflen == 0
end

@inline function next(::Type{T}, itr::SimpleTokenizer) where {T <: Union{Float16,Float32,Float64,Integer}}
    if (curlen = step!(itr)) == -1
        return zero(T)
    else
        return myparse(T, itr.buf, 1, curlen)
    end
end
