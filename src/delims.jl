abstract type DelimiterCodes end

struct SpacesTabsNewlines <: DelimiterCodes end
struct CommasSpacesTabs <: DelimiterCodes end
struct CommasSpacesTabsNewlines <: DelimiterCodes end
struct SemicolonsSpacesTabs <: DelimiterCodes end
struct Newlines <: DelimiterCodes end
struct SpacesTabs <: DelimiterCodes end

@inline match(::Type{SpacesTabsNewlines}, c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{SpacesTabs}, c::UInt8) = c == UInt8(' ') || UInt8('\t')
@inline match(::Type{Newlines}, c::UInt8) = c == UInt8('\t') < c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{CommasSpacesTabs}, c::UInt8) = c == UInt8(',') || match(SpacesTabs, c)
@inline match(::Type{CommasSpacesTabsNewlines}, c::UInt8) = c == UInt8(',') || match(SpacesTabsNewlines, c)
@inline match(::Type{SemicolonsSpacesTabs}, c::UInt8) = c == UInt8(';') || match(SpacesTabs, c)
