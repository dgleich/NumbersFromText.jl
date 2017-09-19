

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



"""
Start is the first index
len is the last valid index in buf to search
"""
function reverse_search_delim(buf::Vector{UInt8}, start::Integer, len::Integer, delim::UInt8)
  for idx = len:-1:start
    if buf[idx] == delim
      return idx
    end
  end
  return start
end

""" Fill up parbuf with bytes such that we end with a delimiter. """
function buffer_to_delim(parbuf, io, minlen, maxlen, delim::UInt8)
  curlen = readbytes!(io, parbuf, minlen)
  if curlen == minlen
    while parbuf[curlen] != delim && !eof(io) && curlen < maxlen
      parbuf[curlen+1] = read(io, UInt8)
      curlen += 1

      if curlen == maxlen && !eof(io)
        throw(ArgumentError("could not find delimiter in $(maxlen-minlen) bytes " *
          "try increasing delimzone"))
      elseif curlen == length(parbuf) # our buffer is full, allocate more space
        resize!(parbuf, min(2*length(parbuf), maxlen))
      end
    end
    # otherwise, we can just return curlen
  else # we got all the data, so just return curlen, i.e. we hit EOF
  end
  return curlen
end

const _default_parbuf_size=512*1024
const _default_delimzone=10
@show Threads.nthreads()

# read in parallel
function parallel_readarrays!(io, as...;
  maxbuf::Int=_default_maxbuf_size, parbuf::Int=_default_parbuf_size,
  nthreads::Int = Threads.nthreads(), delim::UInt8=UInt8('\n'),
  delimzone::Int=_default_delimzone)

  delim_search::Int = delimzone*parbuf

  # allocate buffers and tokenizers for each thread,
  # as well as sub-arrays
  bufs = allocate_buffers(nthreads)
  toks = map(x -> SpaceTokenizer(x, maxbuf), bufs) # create the tokenizers
  par_as = map(_ -> map(x -> zeros(eltype(x), 0), as), 1:nthreads) # create the arrays

  buf::Vector{UInt8} = Vector{UInt8}(2*parbuf)

  while true
    buflen = buffer_to_delim(buf, io, parbuf, delim_search+parbuf, delim)
    if buflen == 0
      break
    end

    nvalid = partition_buffer(buf, buflen, nthreads, bufs, delim)
    Threads.@threads for i=1:nvalid
      reset(toks[i]) # reset the tokenizer
      foreach(x -> resize!(x, 0), par_as[i]) # reset each thread's info
      readarrays!(toks[i], par_as[i]...)
    end
    for j=1:length(as)
      for i=1:nvalid
        append!(as[j], par_as[i][j])
      end
    end
  end

  return as
end

