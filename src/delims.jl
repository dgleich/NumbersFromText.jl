abstract type DelimiterCodes end

struct Spaces <: DelimiterCodes end
@inline match(::Type{Spaces}, c::UInt8) = c == UInt8(' ')

struct Newlines <: DelimiterCodes end
@inline match(::Type{Newlines}, c::UInt8) = UInt8('\t') < c <= UInt8('\r') || c == UInt8('\u85')

struct SpacesTabs <: DelimiterCodes end
@inline match(::Type{SpacesTabs}, c::UInt8) = c == UInt8(' ') || UInt8('\t')

struct SpacesTabsNewlines <: DelimiterCodes end
@inline match(::Type{SpacesTabsNewlines}, c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r') || c == UInt8('\u85')

struct CommasSpacesTabs <: DelimiterCodes end
@inline match(::Type{CommasSpacesTabs}, c::UInt8) = c == UInt8(',') || match(SpacesTabs, c)

struct CommasSpacesTabsNewlines <: DelimiterCodes end
@inline match(::Type{CommasSpacesTabsNewlines}, c::UInt8) = c == UInt8(',') || match(SpacesTabsNewlines, c)

struct SemicolonsSpacesTabs <: DelimiterCodes end
@inline match(::Type{SemicolonsSpacesTabs}, c::UInt8) = c == UInt8(';') || match(SpacesTabs, c)

export Spaces, Newlines, SpacesTabs, SpacesTabsNewlines, CommasSpacesTabs,
  CommasSpacesTabsNewlines, SemicolonsSpacesTabs
