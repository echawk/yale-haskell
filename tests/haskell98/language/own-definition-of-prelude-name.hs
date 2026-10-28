-- A module's own definition of a core Prelude name with a signature (JHC's
-- Doc.Chars.pi :: TextLike a => a): the signature is the definition's.
module Main where
class TL a where ch :: Char -> a
instance TL Char where ch = id
instance TL [a] where ch _ = []

s7, pi :: TL a => a
s7 = ch 'x'
pi = ch 'p'

main = print (s7 :: Char, Main.pi :: String, Main.pi :: Char, Prelude.pi :: Double)
