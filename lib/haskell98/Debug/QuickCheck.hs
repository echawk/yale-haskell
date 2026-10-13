-- Debug.QuickCheck (QuickCheck 1, as GHC 6 shipped it): Gen, Arbitrary
-- with coarbitrary, Property, Config and check.  Random numbers come from
-- Haskell 98's Random, so the cases tried differ from QuickCheck 1's; the
-- instances are QuickCheck 1.0's (no Char), and the reports are its:
-- "OK, passed 100 tests." and "Falsifiable, after n
-- tests:" with the arguments.  (Test.QuickCheck is QuickCheck 2's API.)
module Debug.QuickCheck (
    Gen, generate, choose, elements, oneof, frequency, sized, resize,
    variant, promote, vector, two, three, four,
    Arbitrary(arbitrary, coarbitrary),
    Property, Testable(property), (==>), forAll, label, collect, classify,
    trivial, Result(..),
    Config(Config, configMaxTest, configMaxFail, configSize, configEvery),
    defaultConfig, quickCheck, verboseCheck, test, check
  ) where

import Random
import Data.List (sortBy, group, sort, intersperse)

infixr 0 ==>
infix 1 `classify`

newtype Gen a = Gen (Int -> StdGen -> a)

instance Functor Gen where
  fmap f (Gen g) = Gen (\n r -> f (g n r))

instance Monad Gen where
  return a = Gen (\_ _ -> a)
  Gen m >>= k = Gen (\n r0 -> let (r1, r2) = split r0
                                  Gen m' = k (m n r1)
                              in m' n r2)

runGen :: Gen a -> Int -> StdGen -> a
runGen (Gen g) = g

generate :: Int -> StdGen -> Gen a -> a
generate n rnd (Gen m) = let (size, rnd') = randomR (0, n) rnd in m size rnd'

choose :: Random a => (a, a) -> Gen a
choose bounds = Gen (\_ r -> fst (randomR bounds r))

elements :: [a] -> Gen a
elements xs = fmap (xs !!) (choose (0, length xs - 1))

oneof :: [Gen a] -> Gen a
oneof gens = elements gens >>= id

frequency :: [(Int, Gen a)] -> Gen a
frequency xs = choose (1, sum (map fst xs)) >>= (`pick` xs)
  where pick n ((k, x) : rest)
          | n <= k = x
          | otherwise = pick (n - k) rest
        pick _ [] = error "Debug.QuickCheck.frequency: no generators"

sized :: (Int -> Gen a) -> Gen a
sized fgen = Gen (\n r -> runGen (fgen n) n r)

resize :: Int -> Gen a -> Gen a
resize n (Gen m) = Gen (\_ r -> m n r)

rand :: Gen StdGen
rand = Gen (\_ r -> r)

variant :: Int -> Gen a -> Gen a
variant v (Gen m) = Gen (\n r -> m n (rands r !! (v + 1)))
  where rands r0 = r1 : rands r2 where (r1, r2) = split r0

promote :: (a -> Gen b) -> Gen (a -> b)
promote f = Gen (\n r -> \a -> runGen (f a) n r)

vector :: Arbitrary a => Int -> Gen [a]
vector n = sequence [arbitrary | _ <- [1 .. n]]

two :: Monad m => m a -> m (a, a)
two m = m >>= \a -> m >>= \b -> return (a, b)

three :: Monad m => m a -> m (a, a, a)
three m = m >>= \a -> m >>= \b -> m >>= \c -> return (a, b, c)

four :: Monad m => m a -> m (a, a, a, a)
four m = m >>= \a -> m >>= \b -> m >>= \c -> m >>= \d -> return (a, b, c, d)

class Arbitrary a where
  arbitrary   :: Gen a
  coarbitrary :: a -> Gen b -> Gen b

instance Arbitrary () where
  arbitrary = return ()
  coarbitrary _ = variant 0

instance Arbitrary Bool where
  arbitrary = elements [True, False]
  coarbitrary b = if b then variant 0 else variant 1

instance Arbitrary Int where
  arbitrary = sized (\n -> choose (-n, n))
  coarbitrary n = variant (if n >= 0 then 2 * n else 2 * (-n) + 1)

instance Arbitrary Integer where
  arbitrary = sized (\n -> choose (-toInteger n, toInteger n))
  coarbitrary n = variant (fromInteger (if n >= 0 then 2 * n else 2 * (-n) + 1))

instance Arbitrary Float where
  arbitrary = liftFrac
  coarbitrary x = coarbitrary (decodeFloat x)

instance Arbitrary Double where
  arbitrary = liftFrac
  coarbitrary x = coarbitrary (decodeFloat x)

liftFrac :: Fractional a => Gen a
liftFrac = sized (\n -> do
  a <- choose (-toInteger n * 1000, toInteger n * 1000)
  b <- choose (1, 1000)
  return (fromInteger a / fromInteger b))

instance (Arbitrary a, Arbitrary b) => Arbitrary (a, b) where
  arbitrary = do { a <- arbitrary; b <- arbitrary; return (a, b) }
  coarbitrary (a, b) = coarbitrary a . coarbitrary b

instance (Arbitrary a, Arbitrary b, Arbitrary c) => Arbitrary (a, b, c) where
  arbitrary = do { a <- arbitrary; b <- arbitrary; c <- arbitrary; return (a, b, c) }
  coarbitrary (a, b, c) = coarbitrary a . coarbitrary b . coarbitrary c

instance (Arbitrary a, Arbitrary b, Arbitrary c, Arbitrary d) => Arbitrary (a, b, c, d) where
  arbitrary = do { a <- arbitrary; b <- arbitrary; c <- arbitrary; d <- arbitrary; return (a, b, c, d) }
  coarbitrary (a, b, c, d) = coarbitrary a . coarbitrary b . coarbitrary c . coarbitrary d

instance Arbitrary a => Arbitrary [a] where
  arbitrary = sized (\n -> choose (0, n) >>= vector)
  coarbitrary [] = variant 0
  coarbitrary (a : as) = coarbitrary a . variant 1 . coarbitrary as

instance Arbitrary a => Arbitrary (Maybe a) where
  arbitrary = sized (\n -> if n == 0 then return Nothing
                           else frequency [(1, return Nothing), (3, fmap Just arbitrary)])
  coarbitrary Nothing = variant 0
  coarbitrary (Just a) = variant 1 . coarbitrary a

instance (Arbitrary a, Arbitrary b) => Arbitrary (Either a b) where
  arbitrary = oneof [fmap Left arbitrary, fmap Right arbitrary]
  coarbitrary (Left a) = variant 0 . coarbitrary a
  coarbitrary (Right b) = variant 1 . coarbitrary b

instance (Arbitrary a, Arbitrary b) => Arbitrary (a -> b) where
  arbitrary = promote (`coarbitrary` arbitrary)
  coarbitrary f gen = arbitrary >>= ((`coarbitrary` gen) . f)

-- Properties

data Result = Result { ok :: Maybe Bool, stamp :: [String], arguments :: [String] }

nothing :: Result
nothing = Result { ok = Nothing, stamp = [], arguments = [] }

newtype Property = Prop (Gen Result)

result :: Result -> Property
result res = Prop (return res)

evaluate :: Testable a => a -> Gen Result
evaluate a = gen where Prop gen = property a

class Testable a where
  property :: a -> Property

instance Testable () where
  property _ = result nothing

instance Testable Bool where
  property b = result (nothing { ok = Just b })

instance Testable Result where
  property res = result res

instance Testable Property where
  property prop = prop

instance (Arbitrary a, Show a, Testable b) => Testable (a -> b) where
  property f = forAll arbitrary f

forAll :: (Show a, Testable b) => Gen a -> (a -> b) -> Property
forAll gen body = Prop $ do
  a <- gen
  res <- evaluate (body a)
  return (res { arguments = show a : arguments res })

(==>) :: Testable a => Bool -> a -> Property
True ==> a = property a
False ==> _ = result nothing

label :: Testable a => String -> a -> Property
label s a = Prop (fmap add (evaluate a))
  where add res = res { stamp = s : stamp res }

classify :: Testable a => Bool -> String -> a -> Property
classify True name = label name
classify False _ = property

trivial :: Testable a => Bool -> a -> Property
trivial = (`classify` "trivial")

collect :: (Show a, Testable b) => a -> b -> Property
collect v = label (show v)

-- Testing

data Config = Config
  { configMaxTest :: Int
  , configMaxFail :: Int
  , configSize    :: Int -> Int
  , configEvery   :: Int -> [String] -> String
  }

quick :: Config
quick = Config { configMaxTest = 100, configMaxFail = 1000,
                 configSize = (+ 3) . (`div` 2), configEvery = \_ _ -> "" }

verbose :: Config
verbose = quick { configEvery = \n args -> show n ++ ":\n" ++ unlines args }

defaultConfig :: Config
defaultConfig = quick

test, quickCheck, verboseCheck :: Testable a => a -> IO ()
test = check quick
quickCheck = check quick
verboseCheck = check verbose

check :: Testable a => Config -> a -> IO ()
check config a = do
  rnd <- newStdGen
  tests config (evaluate a) rnd 0 0 []

tests :: Config -> Gen Result -> StdGen -> Int -> Int -> [[String]] -> IO ()
tests config gen rnd0 ntest nfail stamps
  | ntest == configMaxTest config = done "OK, passed" ntest stamps
  | nfail == configMaxFail config = done "Arguments exhausted after" ntest stamps
  | otherwise = do
      putStr (configEvery config ntest (arguments res))
      case ok res of
        Nothing -> tests config gen rnd1 ntest (nfail + 1) stamps
        Just True -> tests config gen rnd1 (ntest + 1) nfail (stamp res : stamps)
        Just False -> putStr ("Falsifiable, after " ++ show ntest ++ " tests:\n"
                              ++ unlines (arguments res))
  where
    res = generate (configSize config ntest) rnd2 gen
    (rnd1, rnd2) = split rnd0

done :: String -> Int -> [[String]] -> IO ()
done mesg ntest stamps = putStr (mesg ++ " " ++ show ntest ++ " tests" ++ table)
  where
    table = display . map entry . reverse . sort . map pairLength . group . sort
            . filter (not . null) $ stamps
    display [] = ".\n"
    display [x] = " (" ++ x ++ ").\n"
    display xs = ".\n" ++ unlines (map (++ ".") xs)
    pairLength xss@(xs : _) = (length xss, xs)
    pairLength [] = (0, [])
    entry (n, xs) = percentage n ntest ++ " " ++ concat (intersperse ", " xs)
    percentage n m = show ((100 * n) `div` m) ++ "%"
