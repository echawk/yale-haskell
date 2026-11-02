import ReexportImplicitPrelude ()
import qualified ReexportImplicitPrelude as R
main :: R.IO ()
main = R.print (R.foo R.+ 1) R.>> R.print (R.map (R.* 2) [1, 2 :: R.Int])
