-- Multi-parameter classes in the style of a parser library (MicroCabal's
-- Text.ParserComb): generic code over TokenMachine tm t | tm -> t, instances
-- with multi-parameter contexts, defaults, forall, an inferred context.
module Main where

class TokenMachine tm t | tm -> t where
  tmNextToken :: tm -> (t, tm)
  tmRawTokens :: tm -> [t]
  tmDescribe  :: tm -> String
  tmDescribe _ = "machine"

tmLeft :: TokenMachine tm t => tm -> Int
tmLeft = length . tmRawTokens

newtype Prsr tm t a = P (tm -> Maybe (a, tm))

runP :: Prsr tm t a -> tm -> Maybe (a, tm)
runP (P p) = p

instance TokenMachine tm t => Functor (Prsr tm t) where
  fmap f (P p) = P (\ s -> case p s of
                             Nothing -> Nothing
                             Just (a, s') -> Just (f a, s'))

instance TokenMachine tm t => Monad (Prsr tm t) where
  return a = P (\ s -> Just (a, s))
  P p >>= k = P (\ s -> case p s of
                          Nothing -> Nothing
                          Just (a, s') -> runP (k a) s')

nextToken :: forall tm t . TokenMachine tm t => Prsr tm t t
nextToken = P (\ s -> if tmLeft s == 0 then Nothing else Just (tmNextToken s))

satisfy :: TokenMachine tm t => (t -> Bool) -> Prsr tm t t
satisfy ok = do
  c <- nextToken
  if ok c then return c else P (\ _ -> Nothing)

many1 :: TokenMachine tm t => Prsr tm t a -> Prsr tm t [a]
many1 p = do { x <- p; xs <- many0 p; return (x:xs) }
  where many0 q = P (\ s -> case runP (many1 q) s of
                              Nothing -> Just ([], s)
                              r -> r)

newtype CharStream = CS String
instance TokenMachine CharStream Char where
  tmNextToken (CS (c:cs)) = (c, CS cs)
  tmRawTokens (CS s) = s

newtype IntStream = IS [Int]
instance TokenMachine IntStream Int where
  tmNextToken (IS (x:xs)) = (x, IS xs)
  tmRawTokens (IS xs) = xs
  tmDescribe _ = "ints"

digits :: Prsr CharStream Char String
digits = many1 (satisfy (`elem` "0123456789"))

-- no signature: the context is inferred
countLeft s = tmLeft s + 1

main :: IO ()
main = do
  print (fmap fst (runP digits (CS "123abc")))
  print (fmap fst (runP (many1 (satisfy even)) (IS [2,4,5,6])))
  print (tmDescribe (CS ""), tmDescribe (IS []), countLeft (IS [1,2,3]))
