-- A qualified operator beginning with a dot and then a colon: M..: is
-- M's .: (aeson's, as Template Haskell's deriveJSON names it).
import qualified QualDotOp as Q
main :: IO ()
main = print (1 Q..: 2, (Q..:) 3 4)
