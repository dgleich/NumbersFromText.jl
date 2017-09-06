

if VERSION < v"0.7.0"
  SimpleIOBuffer = Base.AbstractIOBuffer{Vector{UInt8}}
else
  SimpleIOBuffer = Base.GenericIOBuffer{Vector{UInt8}}
end

function update_io_buffer(io::SimpleIOBuffer,
    buf::Array{UInt8}, start::Integer, size::Integer)

  io.data = buf
  io.size = size
  io.ptr = start
  io.readable = true
  io.writable = false
  io.seekable = true
  io.append = false
  io.mark = -1

end

function _search_for_break(buf::Array{UInt8}, len::Integer, start::Integer, delim::UInt8)
  while start < len
    if buf[start] == delim
      return start
    else
      start += 1
    end
  end
  return -1
end

function allocate_buffers(n::Integer)
  bufs = Vector{SimpleIOBuffer}(n)
  for i=1:n
    bufs[i] = IOBuffer(b"", true, false)
  end
  return bufs
end

""" Divide a buffer into pieces.

This takes a buffer in the form of an Array{UInt8} and
divides it up into (at most) n GenericIOBuffers where
splits occur at delim characters.

The outbufs array has to have length n.

The return value is the number of buffers created in
outbufs.

"""
function partition_buffer(buf::Vector{UInt8}, len::Integer,
    n::Integer, outbufs::Vector{SimpleIOBuffer}, delim::UInt8)

  length(outbufs) < n && throw(ArgumentError("outbufs needs at least $(n) spots" *
    " but only $(length(outbufs)) provided"))

  start = 1 # the start of the current
  nbufs = 0
  while start <= len
    estlen = ceil(Int, len/n) # estimated length
    curend = start + estlen
    if nbufs == n-1 || curend >= len
      # we have to slurp up the remainder! or
      # the next buffer would take us over our available
      # space, so just increment do that position.
      nbufs += 1
      update_io_buffer(outbufs[nbufs], buf, start, len)
      start = len+1
    else
      curend = _search_for_break(buf, len, curend, delim)
      if curend == -1 # didn't find an appropriate break
        curend = len
      end
      nbufs += 1
      update_io_buffer(outbufs[nbufs], buf, start, curend)
      start = curend+1 # start on the next character
    end
  end

  assert(nbufs <= n)

  return nbufs
end
