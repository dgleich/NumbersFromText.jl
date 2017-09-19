abstract type DelimiterTypes end

immutable SpacesTabsNewlines <: DelimiterTypes end
immutable CommasSpacesTabs <: DelimiterTypes end
immutable SemicolonsSpacesTabs <: DelimiterTypes end
immutable Newlines <: DelimiterTypes end
immutable SpacesTabs <: DelimiterTypes end

@inline match(::Type{SpacesTabsNewlines}, c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{SpacesTabs}, c::UInt8) = c == UInt8(' ') || UInt8('\t')
@inline match(::Type{Newlines}, c::UInt8) = c == UInt8('\t') < c <= UInt8('\r') || c == UInt8('\u85')
@inline match(::Type{CommasSpacesTabs}, c::UInt8) = c == UInt8(',') || match(SpacesTabs, c)
@inline match(::Type{SemicolonsSpacesTabs}, c::UInt8) = c == UInt8(';') || match(SpacesTabs, c)
