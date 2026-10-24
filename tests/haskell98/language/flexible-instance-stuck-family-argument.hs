-- [Item t], Item not reduced yet, may still match instance [Char]
-- (Agda's toHtml (List1.toList s) in Highlighting.HTML.Base).
{-# LANGUAGE TypeFamilies, FlexibleInstances #-}
module Main where

import qualified GHC.Exts as IsList (IsList(..))
import Data.List.NonEmpty (NonEmpty(..))

class ToMarkup a where toHtml :: a -> String
instance ToMarkup [Char] where toHtml s = "<p>" ++ s ++ "</p>"

type TokenInfo = (Int, NonEmpty Char, Bool)

render :: [TokenInfo] -> [String]
render = map mkHtml
  where
  mkHtml :: TokenInfo -> String
  mkHtml (pos, s, mi) = show pos ++ toHtml (IsList.toList s)

main :: IO ()
main = mapM_ putStrLn (render [(1, 'a' :| "bc", True)])
