abstract type DelimiterCodes end

immutable SpacesTabsNewlines <: DelimiterCodes end
immutable CommasSpacesTabs <: DelimiterCodes end
immutable SemicolonsSpacesTabs <: DelimiterCodes end
immutable Newlines <: DelimiterCodes end
immutable SpacesTabs <: DelimiterCodes end

@inline match(::Type{SpacesTabsNewlines}, c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{SpacesTabs}, c::UInt8) = c == UInt8(' ') || UInt8('\t')
@inline match(::Type{Newlines}, c::UInt8) = c == UInt8('\t') < c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{CommasSpacesTabs}, c::UInt8) = c == UInt8(',') || match(SpacesTabs, c)
@inline match(::Type{SemicolonsSpacesTabs}, c::UInt8) = c == UInt8(';') || match(SpacesTabs, c)
