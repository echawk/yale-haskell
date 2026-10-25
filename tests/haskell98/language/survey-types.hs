-- Type checking from the Hackage survey: an existential constructor with
-- record fields (uniplate's DataBox), a record update of a rank-n field
-- (tasty's trivialFold { foldSingle = .. }), Control.Monad's foldM over a
-- Foldable (emojis'), tagToEnum# at an enumeration (unicode-data's).
{-# LANGUAGE ExistentialQuantification, RankNTypes, MagicHash #-}
import Control.Monad (foldM)
import qualified Data.Map as M
import GHC.Exts (tagToEnum#)

data Box = forall a . Show a => Box { boxKey :: Int, boxVal :: a }

data F = F { fs :: forall t. Show t => Int -> t -> String, fg :: Int }

g :: Show t => t -> String
g = show

data C = R | G | B deriving (Show, Enum)

main :: IO ()
main = do
  let bs = [Box 1 'c', Box { boxKey = 2, boxVal = True }]
  print (map boxKey bs, [show v | Box _ v <- bs])
  let f0 = F { fs = \_ x -> show x, fg = 1 }
      f1 = f0 { fs = \_ -> g }
  putStrLn (fs f1 3 True ++ fs f0 4 'c')
  print (foldM (\a x -> if x > 0 then Just (a + x) else Nothing) 0 (M.fromList [(1, 2), (2, 3 :: Int)]))
  print (tagToEnum# 2 :: C)
