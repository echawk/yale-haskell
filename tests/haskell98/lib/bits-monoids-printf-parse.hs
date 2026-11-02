-- base 4.16's Data.Bits monoids (And, Ior, Xor, Iff), Text.Printf's
-- FormatParse, System.IO's utf16le and the other encodings (QuickCheck's)
import Data.Bits
import Text.Printf
import System.IO

main :: IO ()
main = do
  print (getAnd (And 12 <> And (10 :: Int)), getIor (mconcat [Ior 1, Ior 2, Ior (4 :: Int)]))
  print (getXor (Xor 6 <> Xor (3 :: Int)), getIff (Iff True <> Iff False))
  print (getAnd (mempty :: And Int), getXor (mempty :: Xor Int))
  let FormatParse m c r = FormatParse "hh" 'd' "rest"
  putStrLn (m ++ [c] ++ r)
  print [utf16le, utf16be, utf32le, utf32be]
