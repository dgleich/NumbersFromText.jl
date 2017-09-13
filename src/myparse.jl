# This file is a part of Julia. License is MIT: https://julialang.org/license
# David Gleich modified it to support parsing Array{UInt8} as well

# Except now I'm not really using this code. See the myparse function
# below for a simple solution.
# Will delete soon!

import Base.Checked: add_with_overflow, mul_with_overflow
import Base.next

## string to integer functions ##

function parse(::Type{T}, c::UInt8, base::Integer=36) where T<:Integer
    a::Int = (base <= 36 ? 10 : 36)
    2 <= base <= 62 || throw(ArgumentError("invalid base: base must be 2 ≤ base ≤ 62, got $base"))
    d = UInt8('0') <= c <= UInt8('9') ? c-UInt8('0')    :
        UInt8('A') <= c <= UInt8('Z') ? c-UInt8('A')+10 :
        UInt8('a') <= c <= UInt8('z') ? c-UInt8('a')+a  : throw(ArgumentError("invalid digit: $(repr(c))"))
    d < base || throw(ArgumentError("invalid base $base digit $(repr(c))"))
    convert(T, d)
end

@inline isspacecode(c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r') || c == UInt8('\u85')

function parseint_next(s::Array{UInt8}, startpos::Int, endpos::Int)
    (0 < startpos <= endpos) || (return UInt8(0), 0, 0)
    j = startpos
    c, startpos = next(s,startpos)
    c, startpos, j
end

function parseint_preamble(signed::Bool, base::Int, s::Array{UInt8}, startpos::Int, endpos::Int)
    c, i, j = parseint_next(s, startpos, endpos)

    while isspacecode(c)
        c, i, j = parseint_next(s,i,endpos)
    end
    (j == 0) && (return 0, 0, 0)

    sgn = 1
    if signed
        if c == UInt8('-') || c == UInt8('+')
            (c == UInt8('-')) && (sgn = -1)
            c, i, j = parseint_next(s,i,endpos)
        end
    end

    while isspacecode(c)
        c, i, j = parseint_next(s,i,endpos)
    end
    (j == 0) && (return 0, 0, 0)

    if base == 0
        if c == UInt8('0') && !done(s,i)
            c, i = next(s,i)
            base = c==UInt8('b') ? 2 : c==UInt8('o') ? 8 : c==UInt8('x') ? 16 : 10
            if base != 10
                c, i, j = parseint_next(s,i,endpos)
            end
        else
            base = 10
        end
    end
    return sgn, base, j
end

function tryparse_internal(::Type{T}, s::Array{UInt8}, startpos::Int, endpos::Int, base_::Integer, raise::Bool) where T<:Integer
    _n = Nullable{T}()
    sgn, base, i = parseint_preamble(T<:Signed, Int(base_), s, startpos, endpos)
    if sgn == 0 && base == 0 && i == 0
        raise && throw(ArgumentError("input string is empty or only contains whitespace"))
        return _n
    end
    if !(2 <= base <= 62)
        raise && throw(ArgumentError("invalid base: base must be 2 ≤ base ≤ 62, got $base"))
        return _n
    end
    if i == 0
        raise && throw(ArgumentError("premature end of integer: $(repr(SubString(s,startpos,endpos)))"))
        return _n
    end
    c, i = parseint_next(s,i,endpos)
    if i == 0
        raise && throw(ArgumentError("premature end of integer: $(repr(SubString(s,startpos,endpos)))"))
        return _n
    end

    base = convert(T,base)
    m::T = div(typemax(T)-base+1,base)
    n::T = 0
    a::Int = base <= 36 ? 10 : 36
    while n <= m
        d::T = UInt8('0') <= c <= UInt8('9') ? c-UInt8('0')    :
               UInt8('A') <= c <= UInt8('Z') ? c-UInt8('A')+10 :
               UInt8('a') <= c <= UInt8('z') ? c-UInt8('a')+a  : base
        if d >= base
            raise && throw(ArgumentError("invalid base $base digit $(repr(c)) in $(repr(String(s[startpos:endpos])))"))
            return _n
        end
        n *= base
        n += d
        if i > endpos
            n *= sgn
            return Nullable{T}(n)
        end
        c, i = next(s,i)
        isspacecode(c) && break
    end
    (T <: Signed) && (n *= sgn)
    while !isspacecode(c)
        d::T = UInt8('0') <= c <= UInt8('9') ? c-UInt8('0')    :
               UInt8('A') <= c <= UInt8('Z') ? c-UInt8('A')+10 :
               UInt8('a') <= c <= UInt8('z') ? c-UInt8('a')+a  : base

        if d >= base
            raise && throw(ArgumentError("invalid base $base digit $(repr(c)) in $(repr(SubString(s,startpos,endpos)))"))
            return _n
        end
        (T <: Signed) && (d *= sgn)

        n, ov_mul = mul_with_overflow(n, base)
        n, ov_add = add_with_overflow(n, d)
        if ov_mul | ov_add
            raise && throw(OverflowError())
            return _n
        end
        (i > endpos) && return Nullable{T}(n)
        c, i = next(s,i)
    end
    while i <= endpos
        c, i = next(s,i)
        if !isspacecode(c)
            raise && throw(ArgumentError("extra characters after whitespace in $(repr(SubString(s,startpos,endpos)))"))
            return _n
        end
    end
    return Nullable{T}(n)
end

@inline function check_valid_base(base)
    if 2 <= base <= 62
        return base
    end
    throw(ArgumentError("invalid base: base must be 2 ≤ base ≤ 62, got $base"))
end

"""
    tryparse(type, str, [base])

Like [`parse`](@ref), but returns a [`Nullable`](@ref) of the requested type. The result
will be null if the string does not contain a valid number.
"""
tryparse(::Type{T}, s::Array{UInt8}, base::Integer) where {T<:Integer} =
    tryparse_internal(T, s, start(s), endof(s), check_valid_base(base), false)
tryparse(::Type{T}, s::Array{UInt8}) where {T<:Integer} =
    tryparse_internal(T, s, start(s), endof(s), 0, false)

#=
function myparse(::Type{T}, s::Array{UInt8}, base::Integer) where T<:Integer
    get(tryparse_internal(T, s, start(s), endof(s), check_valid_base(base), true))
end

function myparse(::Type{T}, s::Array{UInt8}) where T<:Integer
    get(tryparse_internal(T, s, start(s), endof(s), 0, true)) # Zero means, "figure it out"
end

function myparse(::Type{T}, s::Array{UInt8}, pos::Int64, len::Int64) where T<:Integer
    get(tryparse_internal(T, s, pos, len, 0, true)) # Zero means, "figure it out"
end
=#

function myparse(::Type{T}, a::Vector{UInt8}, start::Integer, len::Integer) where {T <: Integer}
  i = start
  n::T = zero(T)
  s::T = one(T)
  if a[1] == UInt8('-')
    s = -s
    i += 1
  elseif a[1] == UInt8('+')
    i += 1
  end
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
myparse(::Type{T}, a::Vector{UInt8}) where {T <: Integer}  = parse_int(T, a, 1, length(a))


@inline tryparse(::Type{Float64}, s::Vector{UInt8}, pos::Int64, len::Int64) =
            ccall(:jl_try_substrtod, Nullable{Float64}, (Ptr{UInt8},Csize_t,Csize_t), s, pos, len)

if VERSION < v"0.6"
    @inline function myparse(::Type{Float64}, s::Vector{UInt8}, pos::Int64, last::Int64)
        result = tryparse(Float64, s, pos-1, last-pos+1)
        if isnull(result)
            throw(ArgumentError("cannot parse $(repr(s)) as $Float64"))
        end
        return result.value
    end
else
    @inline function myparse(::Type{Float64}, s::Vector{UInt8}, pos::Int64, last::Int64)
        result = tryparse(Float64, s, pos-1, last-pos+1)
        if isnull(result)
            throw(ArgumentError("cannot parse $(repr(s)) as $Float64"))
        end
        return unsafe_get(result)
    end
end

ParsableNumbers = Union{Float16,Float32,Float64,Integer}
