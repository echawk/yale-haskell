module Main (main) where
import Text.PrettyPrint
import qualified Text.PrettyPrint.Annotated as A
import Text.PrettyPrint.HughesPJClass (Pretty(pPrint), prettyShow)
main :: IO ()
main = do
  putStrLn (render (hang (text "f") 2 (vcat [text "x" <+> int 1, parens (text "y")])))
  putStrLn (A.renderSpans (A.annotate "k" (A.text "ab") A.<> A.text "c") `seq` "ok")
  putStrLn (prettyShow (Just [1, 2 :: Int]))
