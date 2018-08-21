using DoubleDouble
@inline function convert_to_double(f1::Int64, exp::Int)
  f = Float64(f1)
  r = f1 - Int64(f) # get the remainder
  x = Double{Float64}(f) + Double{Float64}(r)
  #@show x

  maxexp = 308
  minexp = -256

  if exp >= 0
    x *= Double{Float64}(10.0)^(exp)
  else
    if exp < minexp # not sure why this is a good choice, but it seems to be!
      x /= Double{Float64}(10.0)^(-minexp)
      #@show x
      x /= Double{Float64}(10.0)^(-exp + minexp)
      #@show x
    else
      x /= Double{Float64}(10.0)^(-exp)
    end
    #@show x
  end
  Float64(x)
end
""" Create a function called "fname" which takes as input a pair of
strings of the same length. Then checks against an input string.
This is used for fast case-insesntive fixed-string comparison
  to get the "inf" and "nan" parsing in our fast parser


function fname(s::Array{UInt8}, start::Int, len::Int)
  return true if the prefix of s is equal to s1e or s2e

"""
macro check_string(fname, s1e, s2e)
  fbody = quote
    @inline @inbounds function $fname(s::Array{UInt8}, start::Int, len::Int)
      return false
    end
  end
  s1 = eval(s1e)
  s2 = eval(s2e)
  @assert length(s1) == length(s2)

  checks = quote
    if (len-start+1) >= $(length(s1))
    end
  end
  for i=1:length(s1)
    push!(checks.args[2].args[2].args, quote
      @inbounds if s[start+$i-1] != $(s1[i]) && s[start+$i-1] != $(s2[i])
        return false
      end
    end)
  end
  push!(checks.args[2].args[2].args, :(return true))
  #@show checks
  insert!(fbody.args[2].args[2].args[2].args[2].args, 1, checks)
  #@show fbody
  #@show fbody.args[2].args[2].args

  return esc(fbody)
end
@check_string(check_string_inf_nf, b"nf", b"NF")
@check_string(check_string_nan_an, b"an", b"AN")
@check_string(check_string_inf_inity, b"inity", b"INITY")



@inline _isdigit(x::UInt8) = UInt8('0') <= x <= UInt8('9') # if isdigit

""" This is equivalent to boost's extract_uint code to read the next integer.
Note that we don't handle overflow because it is only in the 4-5 bits of the
64-bit integer, and we only have 52 bits of precision in the Float64. So that
we don't have to worry about those digits.

Also, we take as input an initial value of the number, so we can accumulate
across the decimal point.
"""
@inline function parse_uint_and_stop(a::Vector{UInt8}, start::Integer, len::Integer, n::T) where {T <: Integer}
  i = start
  # specialize handling of the first digit so we can return an error
  max_without_overflow = div(typemax(T)-9,10) # the larg
  if _isdigit(a[i]) && i <= len && n <= max_without_overflow
    n *= T(10)
    n += T(a[i]-UInt8('0'))
  else
    return i, false, n
  end
  i += 1
  while i <= len && n <= max_without_overflow
    if _isdigit(a[i])
      n *= T(10)
      n += T(a[i]-UInt8('0'))
    else
      return i, true, n
    end
    i += 1
  end
  return i, true, n
end

@inline function read_digits(a::Vector{UInt8}, i::Integer, len::Integer)
  # slurp up extra digits
  while i <= len
    if !_isdigit(a[i]) # do nothing
      return i
    end
    i += 1
  end
  return i
end

# implementations
# https://opensource.apple.com/source/tcl/tcl-10/tcl/compat/strtod.c
# http://www.boost.org/doc/libs/1_65_0/boost/spirit/home/qi/numeric/detail/real_impl.hpp
# http://www.boost.org/doc/libs/1_65_0/boost/spirit/home/qi/numeric/real_policies.hpp
# http://www.boost.org/doc/libs/1_65_0/boost/spirit/home/qi/numeric/numeric_utils.hpp
@inline function parse_float(::Type{T}, s::Vector{UInt8},
    start::Int64, len::Int64) where {T <: Union{Float32,Float64}}

  i = start

  f = zero(T)

  if len < start
    throw(ArgumentError("cannot parse the empty-string as Float64"))
  end

  negate::Bool = false
  if s[1] == UInt8('-')
    negate = true
    i += 1
  elseif s[1] == UInt8('+')
    i += 1
  end

  #@show String(s)
  #@show negate, i

  f1::Int64 = 0

  # read an integer up to the decimal point
  idecpt, rval1, f1 = parse_uint_and_stop(s, i, len, f1)
  idecpt = read_digits(s, idecpt, len) # get any trailing digits
  f1len = idecpt - i # this is the length of the first part
  i = idecpt

  if rval1 == false
    # check for Inf or NaN
    if len >= i + 2
      # look for inf

      if s[i] == UInt8('i') || s[i] == UInt8('I')
        i+=1
        #@show "here $(String(s[i:len]))"
        if check_string_inf_nf(s, i, len)
          i+=2
          if i > len || check_string_inf_inity(s, i, len)
            if negate
              return -Inf
            else
              return Inf
            end
          end
        end
        throw(ArgumentError("cannot parse \"$(String(s[start:len]))\" as Float64"))
      elseif s[i] == UInt8('n') || s[i] == UInt8('N')
        i += 1
        # look for an
        if check_string_nan_an(s, i, len)
          i+=2
          if i >= len
            return NaN
          elseif i < len && s[i] == UInt8('(')
            i += 1
            while i <= len
              if s[i] == UInt8(')') && i == len
                return NaN
              end
              i+= 1
            end
          end
        end
        throw(ArgumentError("cannot parse \"$(String(s[start:len]))\" as Float64"))
      end
    end
  end

  #@show idecpt, rval1, f1

  ie = i
  frac_digits = 0

  # next thing must be dec pt.
  if i <= len && s[i] == UInt8('.')
    i += 1
    ie, rval2, f1 = parse_uint_and_stop(s, i, len, f1)
    #f1len += ie - i
    frac_digits = ie - i

    ie = read_digits(s, ie, len) # get any trailing digits

    #@show ie, rval2, f1, f1len, frac_digits
  elseif rval1 == false # no first number, and now no deciaml point => invalid
    throw(ArgumentError("cannot parse \"$(String(s[start:len]))\" as Float64"))
  end

  # next thing must be exponent, which is
  i = ie
  eval::Int32 = 0
  if i <= len && (s[i] == UInt8('e') || s[i] == UInt8('E'))
    i += 1

    enegate::Bool = false
    if s[i] == UInt8('-')
      enegate = true
      i += 1
    elseif s[i] == UInt8('+')
      i += 1
    end
    i, rval3, eval = parse_uint_and_stop(s, i, len, eval)
    if enegate
      eval *= Int32(-1)
    end
  end

  exp = eval - frac_digits

  maxexp = 308
  minexp = -307

  #@show f1, frac_digits, eval, exp

  if frac_digits <= 15 && 22 <= exp <= -22
    if exp >= 0
      f = T(f1)*10.0^exp
    else
      f = T(f1)/10.0^(-exp)
    end
  else
    f = convert_to_double(f1, exp)
  end

  if negate
    f = -f
  end

  #@show f, f1, frac_digits, eval, exp

  return f
end

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

import Base.tryparse
@inline tryparse(::Type{Float64}, s::Vector{UInt8}, pos::Int64, len::Int64) =
            ccall(:jl_try_substrtod, Nullable{Float64}, (Ptr{UInt8},Csize_t,Csize_t), s, pos, len)
@inline tryparse(::Type{Float32}, s::Vector{UInt8}, pos::Int64, len::Int64) =
            ccall(:jl_try_substrtof, Nullable{Float32}, (Ptr{UInt8},Csize_t,Csize_t), s, pos, len)


@inline function parse_float_julia(::Type{T}, s::Vector{UInt8}, pos::Int64, last::Int64) where {
            T<:Union{Float32,Float64}}
    result = tryparse(T, s, pos-1, last-pos+1)
    if isnull(result)
        throw(ArgumentError("cannot parse $(repr(s)) as $T"))
    end
    return unsafe_get(result)
end

parse_float_julia(::Type{T}, s::Vector{UInt8}) where {
            T<:Union{Float32,Float64}} = parse_float_julia(T, s, 1, length(s))

@inline function myparse(::Type{T}, s::Vector{UInt8}, pos::Int64, last::Int64) where {
            T<:Union{Float32,Float64}}

    return convert(T, parse_float(Float64, s, pos, last))

end

ParsableNumbers = Union{Float16,Float32,Float64,Integer}
myparse(::Type{T}, a::Vector{UInt8}) where {T <: ParsableNumbers}  = myparse(T, a, 1, length(a))


function parse_test_float(n::Int)
  dtjulia = 0.0
  dtmy = 0.0
  for i=1:n
    # prep the data as a byte-string
    x = rand()
    buf = IOBuffer()
    print(buf, x)
    seek(buf, 0)
    s = readavailable(buf)

    dtjulia += @elapsed parse_float_julia(Float64, s)
    dtmy += @elapsed myparse(Float64, s)
  end
  return dtjulia, dtmy
end

parse_test_float(100)
@show parse_test_float(10000)


function parse_test_int(n::Int)
  dtjulia = 0.0
  dtmy = 0.0
  for i=1:n
    # prep the data as a byte-string
    x = rand(Int64)
    buf = IOBuffer()
    print(buf, x)
    seek(buf, 0)
    s = readavailable(buf)
    seek(buf, 0)
    str = readline(buf)

    dtjulia += @elapsed parse(Int64, str)
    dtmy += @elapsed myparse(Int64, s)
  end
  return dtjulia, dtmy
end
parse_test_int(100)
@show parse_test_int(10000)
