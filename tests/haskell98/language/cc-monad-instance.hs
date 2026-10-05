-- A user-defined state monad as an instance of the Prelude's Monad
-- class, with a partially applied type constructor (State s) as the
-- instance head.  Uses >>=, >> and return directly (no do).
-- (Modern GHC also needs Functor and Applicative instances.)
module Main where

data State s a = State (s -> (a, s))

runState :: State s a -> s -> (a, s)
runState (State f) = f

instance Monad (State s) where
  return x      = State (\s -> (x, s))
  State m >>= k = State (\s -> let (a, s') = m s in runState (k a) s')

get :: State s s
get = State (\s -> (s, s))

put :: s -> State s ()
put s = State (\_ -> ((), s))

fresh :: State Int Int
fresh = get >>= \n -> put (n + 1) >> return n

labels :: State Int [Int]
labels = fresh >>= \a -> fresh >>= \b -> fresh >>= \c -> return [a, b, c]

out :: String
out = let (xs, next) = runState labels 10
      in unwords (map show xs) ++ " next=" ++ show next ++ "\n"

main = appendChan stdout out abort done
