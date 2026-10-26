-- Library pieces from the Hackage survey: lazy Text's Empty and Chunk
-- (attoparsec), Data.Text.Read (doctemplates), STM's Alternative
-- (unliftio), Data for 6-tuples (cmdargs), NonEmpty's inits and tails
-- (base-compat), bitReverse# (bitvec), ansi-terminal's cursorUpLine
-- (tasty).
{-# LANGUAGE MagicHash, PatternSynonyms #-}
import qualified Data.Text as T
import qualified Data.Text.Lazy as L
import Data.Text.Lazy.Internal (Text(..), chunk)
import qualified Data.Text.Read as R
import Control.Applicative ((<|>))
import Control.Concurrent.STM
import Data.Data (Data, toConstr)
import qualified Data.List.NonEmpty as NE
import GHC.Exts (bitReverse8#)
import System.Console.ANSI (cursorUpLineCode, clearFromCursorToLineEndCode)

chunks :: L.Text -> [T.Text]
chunks Empty = []
chunks (Chunk c rest) = c : chunks rest

main :: IO ()
main = do
  print (chunks (L.pack "abc"), chunks (chunk (T.pack "x") L.empty))
  print (R.decimal (T.pack "42 rest") :: Either String (Int, T.Text))
  print (R.signed R.decimal (T.pack "-7") :: Either String (Integer, T.Text))
  print (fmap fst (R.double (T.pack "2.5e2x")), R.hexadecimal (T.pack "ff") :: Either String (Int, T.Text))
  v <- atomically (retry <|> return (3 :: Int))
  print v
  print (toConstr (1 :: Int, 'a', True, (), "s", 2.5 :: Double))
  print (NE.inits [1, 2 :: Int], NE.tails "ab")
  print (bitReverse8# 1, bitReverse8# 6)
  print (cursorUpLineCode 2, clearFromCursorToLineEndCode)
