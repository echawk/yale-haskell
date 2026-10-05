-- The Haskell 98 Ix library.
--
-- The class and its instances are in the Prelude (PreludeCore).
-- Differences from H98:
--   * rangeSize is a function, not a class method: the runtime builds
--     Ix dictionaries for tuples with a fixed layout
--     (src/runtime/tuple-prims.mumble), so Ix cannot gain a method yet.
--   * Ix still has Text as a superclass (a Yale modification), for the
--     same reason.
--
-- rangeSize is from the Haskell 98 Report, libraries/code/Ix.hs:
--   The authors intend this Report to belong to the entire Haskell
--   community, and so we grant permission to copy and distribute it for
--   any purpose, provided that it is reproduced in its entirety,
--   including this Notice.  Modified versions of this Report may also be
--   copied and distributed for any purpose, provided that the modified
--   version is clearly presented as such, and that it does not claim to
--   be a definition of the language Haskell 98.

module Ix ( Ix(range, index, inRange), rangeSize ) where

rangeSize :: (Ix a) => (a,a) -> Int
rangeSize b@(l,h) | null (range b) = 0
                  | otherwise      = index b h + 1
	-- NB: replacing "null (range b)" by  "not (l <= h)"
	-- fails if the bounds are tuples.  For example,
	-- 	(1,2) <= (2,1)
	-- but the range is nevertheless empty
	--	range ((1,2),(2,1)) = []
