import qualified Test.QuickCheck as QC
import Test.QuickCheck (Arbitrary(..), Fun, applyFun, quickCheck, liftArbitrary, liftShrink, chooseInt, generate)

newtype Key = Key String deriving Show
instance QC.Function Key where
  function = QC.functionMap (\(Key s) -> s) Key
instance QC.CoArbitrary Key where
  coarbitrary (Key s) = QC.coarbitrary s

main = do
  quickCheck (\f x -> applyFun (f :: Fun Int Int) x == applyFun f x)
  n <- generate (chooseInt (3, 3))
  xs <- generate (liftArbitrary (return 'z') :: QC.Gen String)
  print (n, all (== 'z') xs, length (liftShrink (const []) [1, 2, 3 :: Int]))
