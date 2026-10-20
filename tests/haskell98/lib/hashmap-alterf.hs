import qualified Data.HashMap.Lazy as HM
import qualified Data.HashMap.Strict as HMS
main = do
  let m = HM.fromList [(1 :: Int, "a"), (2, "b")]
  r <- HM.alterF (\v -> do { print v; return (fmap (++ "!") v) }) 1 m
  print (HM.toList r)
  print (fmap HM.toList (HMS.alterF (const (Just Nothing)) 2 m), fmap HM.size (HM.alterF (\_ -> [Just "x", Nothing]) 3 m))
