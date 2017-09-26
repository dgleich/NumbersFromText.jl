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
end