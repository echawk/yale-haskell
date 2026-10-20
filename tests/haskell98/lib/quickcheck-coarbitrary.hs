import Test.QuickCheck
main = do
  xs <- generate (liftArbitrary (return 'k') :: Gen (Int, Char))
  quickCheck (\f p -> applyFun (f :: Fun (Int, Maybe Bool) Int) p == applyFun f p)
  quickCheck (\f d -> applyFun (f :: Fun (Either Double Word) Int) d == applyFun f d)
  print (snd xs)
