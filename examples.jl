function read_metis_graph(filename)
  open(filename) do fh
  	tok = SimpleTokenizer(fh, SpacesTabs, Newlines)
  	nnodes = next(Int, tok)
  	nedges = next(Int, tok)
  	fmt = 0
  	if find_record_separator(tok)
  	else
  	  fmt = next(Int, tok)
  	end
  	nvweights = 0
  	if fmt == 10 || fmt == 11
  	  nvweights = 1
  	  if find_record_separator(tok) == false
  	    nvweights = next(Int, tok)
  	  end
    end
    if find_record_separator(tok) == false
  	  throw(ArgumentError("invalid METIS file, the first line didn't have correct tokens")
  	end

  	eweights = false
  	if fmt == 1 || fmt == 11
  	  eweights = true
  	end

  	vweights = zeros(Float64, n, nvweights)
  	ei = zeros(Int, nedges*2)
  	ej = zeros(Int, nedges*2)
  	ev = zeros(Int, nedges*2*eweights)
  	curedge = 0

  	# In principle, we could do comment parsing ourselves here...
  	# it'd be a bit ugly.
  	for i=1:nnodes
  	  for j=1:nvweights
  	    vweights[i,j] = next(Float64, tok)
  	  end

  	  while find_record_seperator(tok) == false # while don't see a newline
  	    neigh = next(Int, tok)

  	    curedge += 1
  	    ei[curedge] = i
  	    ej[curedge] = j
  	    if eweights
  	      ev[curedge] = next(Float64, tok)
  	    end
  	  end


  	end
  end
  return ei, ej, ev, vweights
end

function read_snap_graph(filename)
  open(filename) do fh

  end
end


---

Read a matrix of data where the number of columns is inferred from the first line.

	M = readmatrix("myfile.txt") # read a matrix of Float64 data
 	M = readmatrix(Int, "myfile.txt") # read a matrix of Int data

Read an array of data

	a = readarray("myfile.txt")
	a = readarray(Int, "myfile.txt") # read an array of Integer data

Read an array of data inplace

	a = rand(5)
	a = readarray!("myfile.txt", a) # reads Float64s from file

	a = rand(Int, 5)
	a = readarray!("myfile.txt", a) # reads Ints from file (type inferred from array a)

Read multiple arrays of data

	a, b = readarrays("myfile.txt", Float64, Float64) # read alternating numbers as floats
	a, b = readarrays("myfile.txt", Int64, Float64) # read as an [Int, Float64]* sequence

By default, these operations ignore all white-space and commas and just consider the file
as one long string of tokens. If you care about newlines and only want to read valid
files -- A good practice for a library!, say -- then you can specify a record delimiter.

Help! My file has a header or starts with a bunch of comments, and there's no way to
use your built in routine.

Right you are, but there _is_ a way with just a few extra lines. They aren't baked in yet
because I don't have a long enough list of examples to merit specializing on them. The
right interfaces also aren't clear.

	open("filename") do fh; begin
		return split(readline(fh)), readarrays(...; kwargs...)...


Notes



While reading matrices, we need to do a final data transpose, because we read the data
in the wrong order. This doubles the memory requirement. If you have special data and
don't want this, call

	M = readmatrix("myfile.txt"; transpose=false)

You don't want to read a matrix of data with the readarrays function unless. There
are a few optimizations in the readarray function for a single
