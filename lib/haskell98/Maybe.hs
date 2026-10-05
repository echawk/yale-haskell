-- The Haskell 98 Maybe library.
--
-- From the Haskell 98 Report, libraries/code/Maybe.hs:
--   The authors intend this Report to belong to the entire Haskell
--   community, and so we grant permission to copy and distribute it for
--   any purpose, provided that it is reproduced in its entirety,
--   including this Notice.  Modified versions of this Report may also be
--   copied and distributed for any purpose, provided that the modified
--   version is clearly presented as such, and that it does not claim to
--   be a definition of the language Haskell 98.
-- Modified for Yale Haskell: the export list does not repeat the
-- Prelude's names.

module Maybe(
    isJust, isNothing,
    fromJust, fromMaybe, listToMaybe, maybeToList,
    catMaybes, mapMaybe

    -- ...and what the Prelude exports: Maybe(Nothing, Just), maybe.
    -- Yale Haskell cannot re-export Prelude entities yet; they are in
    -- scope anyway through the Prelude.
  ) where

isJust                 :: Maybe a -> Bool
isJust (Just a)        =  True
isJust Nothing         =  False

isNothing	       :: Maybe a -> Bool
isNothing	       =  not . isJust

fromJust               :: Maybe a -> a
fromJust (Just a)      =  a
fromJust Nothing       =  error "Maybe.fromJust: Nothing"

fromMaybe              :: a -> Maybe a -> a
fromMaybe d Nothing    =  d
fromMaybe d (Just a)   =  a

maybeToList            :: Maybe a -> [a]
maybeToList Nothing    =  []
maybeToList (Just a)   =  [a]

listToMaybe            :: [a] -> Maybe a
listToMaybe []         =  Nothing
listToMaybe (a:_)      =  Just a
 
catMaybes              :: [Maybe a] -> [a]
catMaybes ms           =  [ m | Just m <- ms ]

mapMaybe               :: (a -> Maybe b) -> [a] -> [b]
mapMaybe f             =  catMaybes . map f
