module NumbersFromText

include("myparse.jl") # updates to parsing routines to work with Array{UInt8}


include("spacetokenizer.jl")
export SpaceTokenizer

include("readers.jl")
export readmatrix
export readarray, readarray!, readarrays, readarrays!

include("parallel.jl")
export partition_buffer, allocate_buffers

end
