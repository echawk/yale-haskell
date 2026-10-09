-- Unicode in source text: identifiers (Latin-1 and beyond), an operator, string
-- literals, Char functions, show escapes, UTF-8 output and file I/O.
-- Output matches GHC except isSpace: the H98 Report recognises only
-- Latin-1 white space, so U+3000 is not a word separator here.
import Char

data Größe = Klein | Groß deriving (Show, Eq)

λx :: Int -> Int
λx n = n * 2

(→) :: Int -> Int -> Int
a → b = a + b
infixr 5 →

π' :: Double
π' = 3.14159

greet :: String
greet = "héllo wörld λ → € 中文"

main :: IO ()
main = do
  putStrLn greet
  print greet
  print (λx 21, 1 → 2, Groß, π')
  print (map toUpper "straße λ ÿ µ", map toLower "ÀΛΣ")
  print (map isUpper "AλΛ中", map isLower "aλΛ中", map isAlpha "a1λ中→")
  print (map ord "λ€中", chr 8364, maxBound :: Char)
  print ('\x3bb', '\955', "\8594", length "λ→€", [succ 'λ'])
  print (words "a\12288b", isSpace '\160')
  writeFile "/tmp/yale-haskell-unicode-test.txt" greet
  s <- readFile "/tmp/yale-haskell-unicode-test.txt"
  print (s == greet, length s)
  putStrLn (reverse greet)
