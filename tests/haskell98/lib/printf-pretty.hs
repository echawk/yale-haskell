-- Text.Printf (base) and Text.PrettyPrint (pretty): output as GHC's.
import Text.Printf
import Text.PrettyPrint

main :: IO ()
main = do
  printf "%d %s %c %.3f|%5d|%-5d|%x\n" (42 :: Int) "str" 'c' (3.14159 :: Double) (7 :: Int) (7 :: Int) (255 :: Int)
  let s = printf "%03d-%s" (5 :: Int) "x" :: String
  putStrLn s
  putStrLn (render (text "hello" <+> parens (int 5) $$ nest 2 (vcat [text "a", text "b"])))
  putStrLn (renderStyle style { lineLength = 20 } (fsep (map text (words "the quick brown fox jumps over the lazy dog"))))
