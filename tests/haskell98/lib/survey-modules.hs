-- Modules the Hackage survey needed: Control.Applicative.Lift,
-- Data.Functor.Constant, Foreign.C.ConstPtr, GHC.List, GHC.Arr,
-- Control.Monad.ST.Unsafe, Data.ByteString.Short.
import Control.Applicative.Lift
import Data.Functor.Constant
import Foreign.C.ConstPtr
import Foreign.Ptr (nullPtr, Ptr)
import qualified GHC.List as L
import GHC.Arr (unsafeIndex, unsafeRangeSize, listArray, Array)
import Control.Monad.ST
import Control.Monad.ST.Unsafe (unsafeInterleaveST)
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString as B

validate :: Int -> Errors [String] Int
validate n = if n > 0 then pure n else failure ["bad " ++ show n]

main = do
  print (runErrors ((+) <$> validate 1 <*> validate 2))
  print (runErrors ((+) <$> validate 0 <*> validate (-1)))
  print (unConstPtr (ConstPtr nullPtr) == (nullPtr :: Ptr Int))
  print (L.foldl' (+) 0 [1..10 :: Int], (L.build (\c n -> c 1 (c 2 n)) :: [Int]))
  print (unsafeIndex ((0, 9) :: (Int, Int)) 3, unsafeRangeSize ((1, 5) :: (Int, Int)))
  print (runST (unsafeInterleaveST (return (5 :: Int))))
  print (SBS.length (SBS.toShort (B.pack [1,2,3])), getConstant (Constant "k" :: Constant String Int))
