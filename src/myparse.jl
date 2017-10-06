# This file is a part of Julia. License is MIT: https://julialang.org/license
# David Gleich modified it to support parsing Array{UInt8} as well

# Except now I'm not really using this code. See the myparse function
# below for a simple solution.
# Will delete soon!

import Base.Checked: add_with_overflow, mul_with_overflow
import Base.next

function myparse(::Type{T}, a::Vector{UInt8}, start::Integer, len::Integer) where {T <: Integer}
  i = start
  n::T = zero(T)
  s::T = one(T)
  if a[1] == UInt8('-')
    (T <: Unsigned) && throw(ArgumentError("$(String(a[start:len])) is not a valid unsigned integer"))
    s = -s
    i += 1
  elseif a[1] == UInt8('+')
    i += 1
  end
  # specialize handling of the first digit, this enables parsing of bools
  if UInt8('0') <= a[i] <= UInt8('9')
    n += T(a[i]-UInt8('0'))
  else
    throw(ArgumentError("$(String(a[start:len])) is not a valid base 10 integer"))
  end
  i += 1
  max_without_overflow = div(typemax(T)-9,10) # the larg
  while i <= len && n <= max_without_overflow
    if UInt8('0') <= a[i] <= UInt8('9')
      n *= T(10)
      n += T(a[i]-UInt8('0'))
    else
      throw(ArgumentError("$(String(a[start:len])) is not a valid base 10 integer"))
    end
    i += 1
  end
  (T <: Signed) && (n *= s)
  f::Bool = false
  while i <= len
    if UInt8('0') <= a[i] <= UInt8('9')
      d = T(a[i]-UInt8('0'))
      (T <: Signed) && (d *= s)
      n10,f1 = mul_with_overflow(T(10), n)
      f = f|f1
      n,f1 = add_with_overflow(n10,d)
      f = f|f1
    else
      throw(ArgumentError("$(String(a[start:len])) is not a valid base 10 integer"))
    end
    i += 1
  end
  if f
    throw(ArgumentError("$(String(a[start:len])) caused overflow for type $(T)"))
  end
  return n
end

#=
@inline tryparse(::Type{Float64}, s::Vector{UInt8}, pos::Int64, len::Int64) =
            ccall(:jl_try_substrtod, Nullable{Float64}, (Ptr{UInt8},Csize_t,Csize_t), s, pos, len)
@inline tryparse(::Type{Float32}, s::Vector{UInt8}, pos::Int64, len::Int64) =
            ccall(:jl_try_substrtof, Nullable{Float32}, (Ptr{UInt8},Csize_t,Csize_t), s, pos, len)


@inline function myparse(::Type{T}, s::Vector{UInt8}, pos::Int64, last::Int64) where {
            T<:Union{Float32,Float64}}
    result = tryparse(T, s, pos-1, last-pos+1)
    if isnull(result)
        throw(ArgumentError("cannot parse $(repr(s)) as $T"))
    end
    return unsafe_get(result)
end

myparse(::Type{Float16}, s::Vector{UInt8}, pos::Int64, last::Int64) =
  convert(myparse(Float32, s, pos, last))
=#

include("parse-float.jl")

@inline function myparse(::Type{T}, s::Vector{UInt8}, pos::Int64, last::Int64) where {
            T<:Union{Float32,Float64}}

    return convert(T, parse_float(Float64, s, pos, last))

end



ParsableNumbers = Union{Float16,Float32,Float64,Integer}
myparse(::Type{T}, a::Vector{UInt8}) where {T <: ParsableNumbers}  = myparse(T, a, 1, length(a))
