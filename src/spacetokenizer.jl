


const _smallbuf_size = 256
#@show _smallbuf_size

mutable struct SpaceTokenizer{T} 
    io::T
    buf::Array{UInt8,1}
    smallbuf::Array{UInt8,1}
    smallbufpos::Int
    smallbuflen::Int    

    SpaceTokenizer(stream::T) where {T <: IO} = SpaceTokenizer(stream, 2^10)
    SpaceTokenizer(stream::T, initbuf::Int) where {T <: IO} = begin
        smallbuf = Array{UInt8,1}(_smallbuf_size)
        smallbuflen = readbytes!(stream, smallbuf, _smallbuf_size)
        new{T}(stream, Array{UInt8,1}(initbuf), smallbuf, 1, smallbuflen)
    end
end

"""
This could be executed after the underyling IOBuffer has been
reset.
"""
function reset(itr::SpaceTokenizer)
  itr.smallbuflen = readbytes!(itr.io, itr.smallbuf, _smallbuf_size)
  itr.smallbufpos = 1
end

@inline function _read_spaces(itr::SpaceTokenizer)
    #@show String(smallbuf), smallbufpos, smallbuflen
    @inbounds while itr.smallbuflen > 0
        if isspacecode(itr.smallbuf[itr.smallbufpos])
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

#@inline _is_record_code(b::UInt8, itr::SpaceTokenizer{T,S,R}) = match(::Val{S}, b)
#@inline _is_separator_code(b::UInt8, itr::SpaceTokenizer{T,S,R}) = match(::Val{S}, b)

@inline function _buffer_nonspaces(itr)
    curbuf = 0
    @inbounds while itr.smallbuflen > 0
        if isspacecode(itr.smallbuf[itr.smallbufpos])
            break
        else
            curbuf += 1
            if curbuf > length(itr.buf)
               resize!(itr.buf, 2*length(itr.buf)) 
                #throw(ArgumentError("tokensize exceeded buffer"))
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

#@inline function record_sep(itr::SpaceTokenizer)

@inline function step!(itr::SpaceTokenizer)
    # The step function has to read through spaces
    # then store non-spaces into buf
    # Then read through the rest of the spaces
    if _read_spaces(itr)
        return _buffer_nonspaces(itr)
    else
        return -1
    end
end

@inline function end_of_stream(itr::SpaceTokenizer)
    return itr.smallbuflen == 0
end

@inline function next(::Type{T}, itr::SpaceTokenizer) where {T <: Union{Float16,Float32,Float64,Integer}}
    if (curlen = step!(itr)) == -1
        return zero(T)
    else
        return myparse(T, itr.buf, 1, curlen)
    end
end
