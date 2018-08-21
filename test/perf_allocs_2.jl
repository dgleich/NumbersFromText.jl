## This example is good
function myfun(a::AbstractArray{T}, as...) where {T <: Number}
  for i=1:length(as)
    for j=1:length(as[i])
      push!(a, as[i][j])
    end
  end
  a
end

function myfun2(a::AbstractArray{Int}, k::Int)
  a1 = [5]
  a2 = [6, 5]
  for i=1:k
    myfun(a, a1, a2)
  end
end

a = sizehint!(zeros(Int, 0), 10^5)
@time myfun2(a, 3)
@time myfun2(a, 4)
@time myfun2(a, 5)
@time myfun2(a, 5)
@time myfun2(a, 58)


## This example has a hidden allocation on the return

## This example is good
function myfun3(a::AbstractArray{T}, as...) where {T <: Number}
  for i=1:length(as)
    for j=1:length(as[i])
      push!(a, as[i][j])
    end
  end
  return as
end

function myfun4(a::AbstractArray{Int}, k::Int)
  a1 = [5]
  a2 = [6, 5]
  for i=1:k
    myfun3(a, a1, a2)
  end
end

a = sizehint!(zeros(Int, 0), 10^5)
@time myfun4(a, 3)
@time myfun4(a, 4)
@time myfun4(a, 5)
@time myfun4(a, 5)
@time myfun4(a, 58)
