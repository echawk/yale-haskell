-- Control.Parallel.Strategies (the parallel package, version 3's
-- interface): evaluation strategies over par and pseq (Control.Parallel).
-- Eval is a strict identity monad, as in parallel 3.1 (data Eval a =
-- Done a): binding a result evaluates what produced it, so rseq and
-- rdeepseq happen in order and rpar sparks.
module Control.Parallel.Strategies (
    Strategy, using, withStrategy, usingIO, withStrategyIO, dot,
    r0, rseq, rdeepseq, rpar, rparWith,
    evalSeq, SeqStrategy,
    evalTraversable, parTraversable, parFmap,
    evalList, parList, evalListN, parListN, evalListNth, parListNth,
    evalListSplitAt, parListSplitAt, parListChunk, parMap,
    evalBuffer, parBuffer,
    evalTuple2, evalTuple3, parTuple2, parTuple3,
    ($|), ($||), (.|), (.||), (-|), (-||),
    Eval, runEval, runEvalIO, parEval,
    NFData
  ) where

import Control.Parallel (par, pseq)
import Control.DeepSeq (NFData, rnf)
import Data.Traversable (Traversable(traverse))
import Control.Applicative (Applicative(pure, (<*>)))

infixl 0 `using`
infixr 9 `dot`
infixl 0 `withStrategy`
infixl 0 `usingIO`
infixl 0 `withStrategyIO`
infixr 0 $|, $||
infixl 9 .|, .||, -|, -||

data Eval a = Done a

runEval :: Eval a -> a
runEval (Done x) = x

runEvalIO :: Eval a -> IO a
runEvalIO (Done x) = return x

instance Functor Eval where
  fmap f (Done x) = Done (f x)

instance Applicative Eval where
  pure = Done
  Done f <*> Done x = Done (f x)

instance Monad Eval where
  return = Done
  Done x >>= k = k x

-- sparks the evaluation of the whole Eval computation
parEval :: Eval a -> Eval a
parEval m = case runEval m of x -> x `par` Done x

type Strategy a = a -> Eval a

using :: a -> Strategy a -> a
x `using` strat = runEval (strat x)

withStrategy :: Strategy a -> a -> a
withStrategy = flip using

usingIO :: a -> Strategy a -> IO a
x `usingIO` strat = runEvalIO (strat x)

withStrategyIO :: Strategy a -> a -> IO a
withStrategyIO = flip usingIO

dot :: Strategy a -> Strategy a -> Strategy a
strat2 `dot` strat1 = strat2 . runEval . strat1

r0 :: Strategy a
r0 x = Done x

rseq :: Strategy a
rseq x = x `seq` Done x

rdeepseq :: NFData a => Strategy a
rdeepseq x = rnf x `pseq` Done x

rpar :: Strategy a
rpar x = x `par` Done x

-- spark the evaluation of x by strat
rparWith :: Strategy a -> Strategy a
rparWith strat x = r `par` Done (unlift r)
  where r = case strat x of Done y -> y `seq` Lift y

data Lift a = Lift a

unlift :: Lift a -> a
unlift (Lift x) = x

type SeqStrategy a = a -> ()

evalSeq :: SeqStrategy a -> Strategy a
evalSeq strat x = strat x `pseq` Done x

evalTraversable :: Traversable t => Strategy a -> Strategy (t a)
evalTraversable = traverse

parTraversable :: Traversable t => Strategy a -> Strategy (t a)
parTraversable strat = evalTraversable (rparWith strat)

parFmap :: Traversable t => Strategy b -> (a -> b) -> t a -> t b
parFmap strat f = (`using` parTraversable strat) . fmap f

evalList :: Strategy a -> Strategy [a]
evalList _ [] = Done []
evalList strat (x:xs) = do x' <- strat x
                           xs' <- evalList strat xs
                           return (x':xs')

parList :: Strategy a -> Strategy [a]
parList strat = evalList (rparWith strat)

evalListSplitAt :: Int -> Strategy [a] -> Strategy [a] -> Strategy [a]
evalListSplitAt n stratPref stratSuff xs =
  let (ys, zs) = splitAt n xs
  in do ys' <- stratPref ys
        zs' <- stratSuff zs
        return (ys' ++ zs')

parListSplitAt :: Int -> Strategy [a] -> Strategy [a] -> Strategy [a]
parListSplitAt n stratPref stratSuff =
  evalListSplitAt n (rparWith stratPref) (rparWith stratSuff)

evalListN :: Int -> Strategy a -> Strategy [a]
evalListN n strat = evalListSplitAt n (evalList strat) r0

parListN :: Int -> Strategy a -> Strategy [a]
parListN n strat = evalListN n (rparWith strat)

evalListNth :: Int -> Strategy a -> Strategy [a]
evalListNth n strat = evalListSplitAt n r0 (evalListN 1 strat)

parListNth :: Int -> Strategy a -> Strategy [a]
parListNth n strat = evalListNth n (rparWith strat)

parListChunk :: Int -> Strategy a -> Strategy [a]
parListChunk n strat xs
  | n <= 1 = parList strat xs
  | otherwise = fmap concat (parList (evalList strat) (chunk n xs))

chunk :: Int -> [a] -> [[a]]
chunk _ [] = []
chunk n xs = as : chunk n bs where (as, bs) = splitAt n xs

parMap :: Strategy b -> (a -> b) -> [a] -> [b]
parMap strat f = (`using` parList strat) . map f

-- a rolling buffer: evaluating an element first evaluates (or sparks)
-- the one n places further on
evalBufferWHNF :: Int -> Strategy [a]
evalBufferWHNF n0 xs0 = Done (ret xs0 (start n0 xs0))
  where ret (x:xs) (y:ys) = y `pseq` (x : ret xs ys)
        ret xs _ = xs
        start 0 ys = ys
        start _ [] = []
        start n (y:ys) = y `pseq` start (n - 1) ys

parBufferWHNF :: Int -> Strategy [a]
parBufferWHNF n0 xs0 = Done (ret xs0 (start n0 xs0))
  where ret (x:xs) (y:ys) = y `par` (x : ret xs ys)
        ret xs _ = xs
        start 0 ys = ys
        start _ [] = []
        start n (y:ys) = y `par` start (n - 1) ys

evalBuffer :: Int -> Strategy a -> Strategy [a]
evalBuffer n strat = evalBufferWHNF n . map (withStrategy strat)

parBuffer :: Int -> Strategy a -> Strategy [a]
parBuffer n strat = parBufferWHNF n . map (withStrategy strat)

evalTuple2 :: Strategy a -> Strategy b -> Strategy (a, b)
evalTuple2 strat1 strat2 (x1, x2) = do x1' <- strat1 x1
                                       x2' <- strat2 x2
                                       return (x1', x2')

evalTuple3 :: Strategy a -> Strategy b -> Strategy c -> Strategy (a, b, c)
evalTuple3 strat1 strat2 strat3 (x1, x2, x3) = do x1' <- strat1 x1
                                                  x2' <- strat2 x2
                                                  x3' <- strat3 x3
                                                  return (x1', x2', x3')

parTuple2 :: Strategy a -> Strategy b -> Strategy (a, b)
parTuple2 strat1 strat2 = evalTuple2 (rparWith strat1) (rparWith strat2)

parTuple3 :: Strategy a -> Strategy b -> Strategy c -> Strategy (a, b, c)
parTuple3 strat1 strat2 strat3 =
  evalTuple3 (rparWith strat1) (rparWith strat2) (rparWith strat3)

-- function application and composition with a strategy for the argument
($|) :: (a -> b) -> Strategy a -> a -> b
f $| s = \x -> let z = x `using` s in z `pseq` f z

($||) :: (a -> b) -> Strategy a -> a -> b
f $|| s = \x -> let z = x `using` s in z `par` f z

(.|) :: (b -> c) -> Strategy b -> (a -> b) -> (a -> c)
(.|) f s g = \x -> let z = g x `using` s in z `pseq` f z

(.||) :: (b -> c) -> Strategy b -> (a -> b) -> (a -> c)
(.||) f s g = \x -> let z = g x `using` s in z `par` f z

(-|) :: (a -> b) -> Strategy b -> (b -> c) -> (a -> c)
(-|) f s g = \x -> let z = f x `using` s in z `pseq` g z

(-||) :: (a -> b) -> Strategy b -> (b -> c) -> (a -> c)
(-||) f s g = \x -> let z = f x `using` s in z `par` g z
