{-# LANGUAGE TypeOperators #-}
-- Test.QuickCheck (QuickCheck 2), a subset: Gen, Arbitrary (with
-- shrink), the common generators and combinators, Testable and
-- quickCheck.  Random numbers come from Haskell 98's Random, so the cases
-- tried differ from QuickCheck's; shrinking is a simple greedy search.
module Test.QuickCheck (
    Gen, generate, sample, sample', choose, elements, oneof, frequency,
    sized, getSize, resize, scale, listOf, listOf1, vector, vectorOf, suchThat,
    suchThatMaybe, infiniteListOf, sublistOf, shuffle, variant,
    Arbitrary(arbitrary, shrink), CoArbitrary(coarbitrary),
    arbitrarySizedIntegral, arbitrarySizedBoundedIntegral, arbitraryBoundedEnum, shrinkIntegral, shrinkList,
    Property, Testable(property), (==>), forAll, forAllShrink,
    once, withMaxSuccess, ioProperty, idempotentIOProperty, mapPropResult,
    counterexample, label, collect, classify, cover, (.&&.), (.||.),
    conjoin, disjoin, (===), quickCheck, quickCheckWith, verboseCheck,
    Args(Args, maxSuccess, maxSize), stdArgs, Result(..), isSuccess, quickCheckResult, quickCheckWithResult,
    NonNegative(NonNegative, getNonNegative), Positive(Positive, getPositive),
    chooseInt, Arbitrary1(liftArbitrary, liftShrink), arbitrary1, shrink1,
    Function(function), functionMap, (:->), Fun(Fun), applyFun
  ) where

import PreludeModern (Applicative(pure, (<*>)))
import Random
import Data.List (sortBy)
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Word (Word, Word8, Word16, Word32, Word64)
import System.IO.Unsafe (unsafePerformIO)

infixr 0 ==>
infixr 1 .&&., .||.
infix 4 ===

newtype Gen a = MkGen (StdGen -> Int -> a)

unGen :: Gen a -> StdGen -> Int -> a
unGen (MkGen f) = f

instance Functor Gen where
  fmap f (MkGen g) = MkGen (\r n -> f (g r n))

instance Applicative Gen where
  pure x = MkGen (\_ _ -> x)
  MkGen f <*> MkGen x = MkGen (\r n -> let (r1, r2) = split r in f r1 n (x r2 n))

instance Monad Gen where
  return x = MkGen (\_ _ -> x)
  MkGen m >>= k = MkGen (\r n -> let (r1, r2) = split r in unGen (k (m r1 n)) r2 n)

generate :: Gen a -> IO a
generate g = do
  r <- newStdGen
  return (unGen g r 30)

sample' :: Gen a -> IO [a]
sample' g = mapM (\n -> fmap (\r -> unGen g r n) newStdGen) [0, 2 .. 20]

sample :: Show a => Gen a -> IO ()
sample g = sample' g >>= mapM_ print

variant :: Integral n => n -> Gen a -> Gen a
variant k (MkGen g) = MkGen (\r n -> g (iterate (snd . split) r !! (1 + fromIntegral (abs k) `mod` 64)) n)

sized :: (Int -> Gen a) -> Gen a
sized f = MkGen (\r n -> unGen (f n) r n)

getSize :: Gen Int
getSize = sized return

resize :: Int -> Gen a -> Gen a
resize n (MkGen g) = MkGen (\r _ -> g r n)

scale :: (Int -> Int) -> Gen a -> Gen a
scale f g = sized (\n -> resize (f n) g)

choose :: Random a => (a, a) -> Gen a
choose rng = MkGen (\r _ -> fst (randomR rng r))

elements :: [a] -> Gen a
elements [] = error "QuickCheck.elements used with empty list"
elements xs = fmap (xs !!) (choose (0, length xs - 1))

oneof :: [Gen a] -> Gen a
oneof [] = error "QuickCheck.oneof used with empty list"
oneof gs = choose (0, length gs - 1) >>= (gs !!)

frequency :: [(Int, Gen a)] -> Gen a
frequency [] = error "QuickCheck.frequency used with empty list"
frequency xs = choose (1, sum (map fst xs)) >>= pick xs
  where pick ((k, g) : ys) n | n <= k = g
                             | otherwise = pick ys (n - k)
        pick [] _ = error "QuickCheck.pick"

listOf :: Gen a -> Gen [a]
listOf g = sized (\n -> choose (0, n) >>= \k -> vectorOf k g)

listOf1 :: Gen a -> Gen [a]
listOf1 g = sized (\n -> choose (1, max 1 n) >>= \k -> vectorOf k g)

vector :: Arbitrary a => Int -> Gen [a]
vector k = vectorOf k arbitrary

vectorOf :: Int -> Gen a -> Gen [a]
vectorOf k g = sequence (replicate k g)

infiniteListOf :: Gen a -> Gen [a]
infiniteListOf g = MkGen (\r n -> map (\r' -> unGen g r' n) (splits r))
  where splits r = let (a, b) = split r in a : splits b

suchThat :: Gen a -> (a -> Bool) -> Gen a
suchThat g p = suchThatMaybe g p >>= maybe (sized (\n -> resize (n + 1) (suchThat g p))) return

suchThatMaybe :: Gen a -> (a -> Bool) -> Gen (Maybe a)
suchThatMaybe g p = sized (\n -> try n (2 * n + 10))
  where try _ 0 = return Nothing
        try k m = do x <- resize k g
                     if p x then return (Just x) else try (k + 1) (m - 1)

sublistOf :: [a] -> Gen [a]
sublistOf xs = fmap (map snd . filter fst . flip zip xs) (vectorOf (length xs) arbitrary)

shuffle :: [a] -> Gen [a]
shuffle xs = do
  ks <- vectorOf (length xs) (choose (0, 1000000 :: Int))
  return (map snd (sortBy (\a b -> compare (fst a) (fst b)) (zip ks xs)))

-- Arbitrary

class Arbitrary a where
  arbitrary :: Gen a
  shrink :: a -> [a]
  shrink _ = []

class CoArbitrary a where
  coarbitrary :: a -> Gen b -> Gen b

arbitrarySizedIntegral :: Integral a => Gen a
arbitrarySizedIntegral = sized (\n -> fmap fromInteger (choose (negate (toInteger n), toInteger n)))

arbitraryBoundedEnum :: (Bounded a, Enum a) => Gen a
arbitraryBoundedEnum = elements [minBound .. maxBound]

shrinkIntegral :: Integral a => a -> [a]
shrinkIntegral x = [x' | x' <- takeWhile (/= x) (0 : map (x -) (halves x)), abs x' < abs x]
  where halves 0 = []
        halves n = let h = n `quot` 2 in if h == 0 then [n] else h : halves h

shrinkList :: (a -> [a]) -> [a] -> [[a]]
shrinkList shr xs = removes ++ shrinkOne xs
  where removes = [take i xs ++ drop (i + 1) xs | i <- [0 .. length xs - 1]]
        shrinkOne [] = []
        shrinkOne (y : ys) = [y' : ys | y' <- shr y] ++ [y : ys' | ys' <- shrinkOne ys]

instance Arbitrary () where arbitrary = return ()
instance Arbitrary Bool where
  arbitrary = elements [False, True]
  shrink True = [False]
  shrink False = []
instance Arbitrary Ordering where arbitrary = elements [LT, EQ, GT]
instance Arbitrary Int where
  arbitrary = arbitrarySizedIntegral
  shrink = shrinkIntegral
instance Arbitrary Int8 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Int16 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Int32 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Int64 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Word where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Word8 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Word16 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Word32 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral
instance Arbitrary Word64 where
  arbitrary = arbitrarySizedBoundedIntegral
  shrink = shrinkIntegral

-- Integers of a bounded type, of magnitude up to the size (QuickCheck's
-- arbitrarySizedBoundedIntegral, clamped to the type's range).
arbitrarySizedBoundedIntegral :: (Bounded a, Integral a) => Gen a
arbitrarySizedBoundedIntegral = g
  where g = sized (\n ->
              let lo = max (toInteger (minBound `asTypeOf` genValue g)) (negate (toInteger n))
                  hi = min (toInteger (maxBound `asTypeOf` genValue g)) (toInteger n)
              in fmap fromInteger (choose (lo, hi)))

genValue :: Gen a -> a
genValue _ = undefined

instance Arbitrary Integer where
  arbitrary = arbitrarySizedIntegral
  shrink = shrinkIntegral
instance Arbitrary Char where
  arbitrary = frequency [(3, choose ('a', 'z')), (1, choose (' ', '~'))]
instance Arbitrary Double where
  arbitrary = sized (\n -> let m = fromIntegral n in choose (negate m, m))
instance Arbitrary Float where
  arbitrary = sized (\n -> let m = fromIntegral n in choose (negate m, m))
instance Arbitrary a => Arbitrary [a] where
  arbitrary = listOf arbitrary
  shrink = shrinkList shrink
instance Arbitrary a => Arbitrary (Maybe a) where
  arbitrary = frequency [(1, return Nothing), (3, fmap Just arbitrary)]
  shrink Nothing = []
  shrink (Just x) = Nothing : map Just (shrink x)
instance (Arbitrary a, Arbitrary b) => Arbitrary (Either a b) where
  arbitrary = oneof [fmap Left arbitrary, fmap Right arbitrary]
instance (Arbitrary a, Arbitrary b) => Arbitrary (a, b) where
  arbitrary = do { a <- arbitrary; b <- arbitrary; return (a, b) }
  shrink (a, b) = [(a', b) | a' <- shrink a] ++ [(a, b') | b' <- shrink b]
instance (Arbitrary a, Arbitrary b, Arbitrary c) => Arbitrary (a, b, c) where
  arbitrary = do { a <- arbitrary; b <- arbitrary; c <- arbitrary; return (a, b, c) }
instance (Ord k, Arbitrary k, Arbitrary v) => Arbitrary (Map.Map k v) where
  arbitrary = fmap Map.fromList arbitrary
  shrink m = map Map.fromList (shrink (Map.toList m))
instance (Ord a, Arbitrary a) => Arbitrary (Set.Set a) where
  arbitrary = fmap Set.fromList arbitrary
instance (CoArbitrary a, Arbitrary b) => Arbitrary (a -> b) where
  arbitrary = MkGen (\r n x -> unGen (coarbitrary x arbitrary) r n)

instance CoArbitrary Bool where
  coarbitrary b = variant (if b then 1 else 0 :: Int)
instance CoArbitrary Int where
  coarbitrary n = variant n
instance CoArbitrary Integer where
  coarbitrary n = variant n
instance CoArbitrary Char where
  coarbitrary c = variant (fromEnum c)
instance CoArbitrary a => CoArbitrary [a] where
  coarbitrary [] = variant (0 :: Int)
  coarbitrary (x : xs) = variant (1 :: Int) . coarbitrary x . coarbitrary xs

newtype NonNegative a = NonNegative { getNonNegative :: a } deriving (Eq, Ord, Show)
newtype Positive a = Positive { getPositive :: a } deriving (Eq, Ord, Show)
instance (Num a, Ord a, Arbitrary a) => Arbitrary (NonNegative a) where
  arbitrary = fmap (NonNegative . abs) arbitrary
instance (Num a, Ord a, Arbitrary a) => Arbitrary (Positive a) where
  arbitrary = fmap (Positive . (+ 1) . abs) arbitrary

-- Properties: a test gives Nothing (discarded) or Just (passed, messages);
-- MaxTests is the number of tests the property asks for (once).

data Property = MkProperty (Maybe Int) (Gen (Maybe (Bool, [String])))

propGen :: Gen (Maybe (Bool, [String])) -> Property
propGen g = MkProperty Nothing g

unProperty :: Property -> Gen (Maybe (Bool, [String]))
unProperty (MkProperty _ g) = g

propMax :: Property -> Maybe Int
propMax (MkProperty m _) = m

-- the test results of P changed by F, keeping P's test count
mapPropResult :: Testable p => (Maybe (Bool, [String]) -> Maybe (Bool, [String])) -> p -> Property
mapPropResult f p = let q = property p in MkProperty (propMax q) (fmap f (unProperty q))

once :: Testable p => p -> Property
once = withMaxSuccess 1

withMaxSuccess :: Testable p => Int -> p -> Property
withMaxSuccess n p = MkProperty (Just n) (unProperty (property p))

-- the action runs when the test does (as QuickCheck's ioProperty)
ioProperty, idempotentIOProperty :: Testable p => IO p -> Property
ioProperty m = propGen (MkGen (\r n -> unGen (unProperty (property (unsafePerformIO m))) r n))
idempotentIOProperty = ioProperty

class Testable a where
  property :: a -> Property

instance Testable Bool where
  property b = propGen (return (Just (b, [])))

instance Testable () where
  property () = property True

instance Testable Property where
  property p = p

instance Testable a => Testable (Gen a) where
  property g = propGen (g >>= unProperty . property)

instance (Arbitrary a, Show a, Testable b) => Testable (a -> b) where
  property f = forAllShrink arbitrary shrink f

forAll :: (Show a, Testable b) => Gen a -> (a -> b) -> Property
forAll g f = forAllShrink g (const []) f

forAllShrink :: (Show a, Testable b) => Gen a -> (a -> [a]) -> (a -> b) -> Property
forAllShrink g _ f = propGen (do
  x <- g
  r <- unProperty (property (f x))
  return (fmap (\(ok, msgs) -> (ok, show x : msgs)) r))

(==>) :: Testable b => Bool -> b -> Property
False ==> _ = propGen (return Nothing)
True ==> p = property p

counterexample :: Testable p => String -> p -> Property
counterexample s = mapPropResult (fmap (\(ok, ms) -> (ok, ms ++ [s])))

label, collect :: (Show l, Testable p) => l -> p -> Property
label _ = property
collect _ = property

classify :: Testable p => Bool -> String -> p -> Property
classify _ _ = property

cover :: Testable p => Double -> Bool -> String -> p -> Property
cover _ _ _ = property

(.&&.), (.||.) :: (Testable p, Testable q) => p -> q -> Property
p .&&. q = conjoin [property p, property q]
p .||. q = disjoin [property p, property q]

conjoin, disjoin :: Testable p => [p] -> Property
conjoin ps = propGen (fmap combine (mapM (unProperty . property) ps))
  where combine rs = if any (== Nothing) (map (fmap fst) rs) then Nothing
                     else Just (all (maybe True fst) rs, concatMap (maybe [] snd) rs)
disjoin ps = propGen (fmap combine (mapM (unProperty . property) ps))
  where combine rs = Just (any (maybe False fst) rs, concatMap (maybe [] snd) rs)

(===) :: (Eq a, Show a) => a -> a -> Property
x === y = counterexample (show x ++ (if x == y then " == " else " /= ") ++ show y) (x == y)

data Args = Args { maxSuccess :: Int, maxSize :: Int }

stdArgs :: Args
stdArgs = Args 100 100

data Result = Success { numTests :: Int, numDiscarded :: Int }
            | Failure { numTests :: Int, failingCase :: [String] }
            | GaveUp { numTests :: Int }
  deriving Show

isSuccess :: Result -> Bool
isSuccess r = case r of
  Success _ _ -> True
  _ -> False

quickCheck :: Testable p => p -> IO ()
quickCheck p = quickCheckWith stdArgs p

verboseCheck :: Testable p => p -> IO ()
verboseCheck = quickCheck

quickCheckWith :: Testable p => Args -> p -> IO ()
quickCheckWith args p = quickCheckWithResult args p >> return ()

-- The report, as QuickCheck prints it.
report :: Result -> IO ()
report r = case r of
  Success n d -> putStrLn ("+++ OK, passed " ++ show n ++ (if n == 1 then " test" else " tests")
                           ++ (if d > 0 then "; " ++ show d ++ " discarded." else "."))
  GaveUp n -> putStrLn ("*** Gave up! Passed only " ++ show n ++ " tests.")
  Failure n cs -> do
    putStrLn ("*** Failed! Falsified (after " ++ show (n + 1) ++ " test" ++ (if n == 0 then "" else "s") ++ "):")
    mapM_ putStrLn cs

quickCheckResult :: Testable p => p -> IO Result
quickCheckResult = quickCheckWithResult stdArgs

quickCheckWithResult :: Testable p => Args -> p -> IO Result
quickCheckWithResult args p = newStdGen >>= \r -> let res = go r 0 0 in report res >> return res
  where
    prop = property p
    limit = maybe (maxSuccess args) id (propMax prop)
    go r passed discarded
      | passed >= limit = Success passed discarded
      | discarded > 10 * limit = GaveUp passed
      | otherwise =
          let (r1, r2) = split r
              -- discarded cases make the size grow too
              size = min (maxSize args)
                         (((passed + discarded `div` 2) * maxSize args) `div` max 1 limit)
          in case unGen (unProperty prop) r1 size of
               Nothing -> go r2 passed (discarded + 1)
               Just (True, _) -> go r2 (passed + 1) discarded
               Just (False, cs) -> Failure passed cs

chooseInt :: (Int, Int) -> Gen Int
chooseInt = choose

-- QuickCheck 2's lifted classes, for a type constructor
class Arbitrary1 f where
  liftArbitrary :: Gen a -> Gen (f a)
  liftShrink :: (a -> [a]) -> f a -> [f a]
  liftShrink _ _ = []

arbitrary1 :: (Arbitrary1 f, Arbitrary a) => Gen (f a)
arbitrary1 = liftArbitrary arbitrary

shrink1 :: (Arbitrary1 f, Arbitrary a) => f a -> [f a]
shrink1 = liftShrink shrink

instance Arbitrary1 [] where
  liftArbitrary g = sized (\n -> do { k <- choose (0, n); vectorOf k g })
  liftShrink shr xs = [ take i xs ++ drop (i + 1) xs | i <- [0 .. length xs - 1] ]
                      ++ [ take i xs ++ [y] ++ drop (i + 1) xs
                         | i <- [0 .. length xs - 1], y <- shr (xs !! i) ]

instance Arbitrary1 Maybe where
  liftArbitrary g = frequency [(1, return Nothing), (3, fmap Just g)]
  liftShrink shr (Just x) = Nothing : map Just (shr x)
  liftShrink _ Nothing = []

-- QuickCheck 2's generated functions: here a function and nothing more
-- (no table to shrink or show)
infixr 0 :->
newtype a :-> c = Fn (a -> c)

class Function a where
  function :: (a -> b) -> (a :-> b)
  function = Fn

functionMap :: Function b => (a -> b) -> (b -> a) -> (a -> c) -> (a :-> c)
functionMap _ _ = Fn

data Fun a b = Fun (a :-> b) (a -> b)

applyFun :: Fun a b -> a -> b
applyFun (Fun _ f) = f

instance (CoArbitrary a, Arbitrary b) => Arbitrary (Fun a b) where
  arbitrary = do
    f <- promote (\a -> coarbitrary a arbitrary)
    return (Fun (Fn f) f)

promote :: (a -> Gen b) -> Gen (a -> b)
promote f = MkGen (\r n -> \a -> unGen (f a) r n)

instance Show (Fun a b) where
  show _ = "<fun>"

instance Function ()
instance Function Bool
instance Function Char
instance Function Int
instance Function Integer
instance Function Double
instance Function Word
instance Function a => Function [a]
instance Function a => Function (Maybe a)
instance (Function a, Function b) => Function (Either a b)
instance (Function a, Function b) => Function (a, b)

instance Arbitrary a => Arbitrary1 ((,) a) where
  liftArbitrary g = do { a <- arbitrary; b <- g; return (a, b) }
  liftShrink shr (a, b) = [ (a', b) | a' <- shrink a ] ++ [ (a, b') | b' <- shr b ]

instance Arbitrary1 (Either e) where
  liftArbitrary g = fmap Right g

instance (CoArbitrary a, CoArbitrary b) => CoArbitrary (a, b) where
  coarbitrary (a, b) = coarbitrary a . coarbitrary b

instance (CoArbitrary a, CoArbitrary b, CoArbitrary c) => CoArbitrary (a, b, c) where
  coarbitrary (a, b, c) = coarbitrary a . coarbitrary b . coarbitrary c

instance (CoArbitrary a, CoArbitrary b) => CoArbitrary (Either a b) where
  coarbitrary (Left a) = variant (0 :: Int) . coarbitrary a
  coarbitrary (Right b) = variant (1 :: Int) . coarbitrary b

instance CoArbitrary () where
  coarbitrary _ = id

instance (Function a, Function b, Function c) => Function (a, b, c)

instance CoArbitrary a => CoArbitrary (Maybe a) where
  coarbitrary Nothing = variant (0 :: Int)
  coarbitrary (Just a) = variant (1 :: Int) . coarbitrary a
instance CoArbitrary Double where
  coarbitrary x = coarbitrary (decodeFloat x)
instance CoArbitrary Float where
  coarbitrary x = coarbitrary (decodeFloat x)
instance CoArbitrary Word where coarbitrary = variant
instance CoArbitrary Word8 where coarbitrary = variant
instance CoArbitrary Word16 where coarbitrary = variant
instance CoArbitrary Word32 where coarbitrary = variant
instance CoArbitrary Word64 where coarbitrary = variant
instance CoArbitrary Int8 where coarbitrary = variant
instance CoArbitrary Int16 where coarbitrary = variant
instance CoArbitrary Int32 where coarbitrary = variant
instance CoArbitrary Int64 where coarbitrary = variant
