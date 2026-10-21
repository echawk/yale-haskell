import Data.Coerce (coerce)
import Data.Ord (Down(..))
import qualified Data.Map as M

newtype MaxMap k a = MaxMap (M.Map (Down k) a)

insertMax :: Ord k => k -> a -> MaxMap k a -> MaxMap k a
insertMax k a (MaxMap m) = MaxMap (M.insert (Down k) a m)

firstMax :: Ord k => MaxMap k a -> Maybe (Down k, a)
firstMax = coerce lookupMinOrd

lookupMinOrd :: Ord k => M.Map k a -> Maybe (k, a)
lookupMinOrd m = if M.null m then Nothing else M.lookupMin m

sizeMax :: MaxMap k a -> Int
sizeMax = coerce (M.size :: M.Map (Down k) a -> Int)

keysMax :: MaxMap k a -> [Down k]
keysMax = coerce M.keys

main :: IO ()
main = do
  let m = insertMax 3 'c' (insertMax 5 'e' (MaxMap M.empty))
  print (fmap fst (firstMax m), keysMax m)
