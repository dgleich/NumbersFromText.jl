module NumbersFromText

include("myparse.jl") # updates to parsing routines to work with Array{UInt8}

include("spacetokenizer.jl")
export SpaceTokenizer, DelimiterCodes

include("readers.jl")
export readmatrix
export readarray, readarray!, readarrays, readarrays!

include("parallel.jl")
export partition_buffer, allocate_buffers, parallel_readarrays!

end
