{-# LANGUAGE ScopedTypeVariables #-}
-- A pattern signature binds its type variables not in scope, over the
-- clause (bifunctors' traverseBiaEither: Left (e :: e) ... where m :: Either e x)
f :: Either e Int -> (Either e Bool, Either e Char)
f (Right n) = (Right (n > 0), Right 'x')
f (Left (e :: e)) = (m, m)
  where
    m :: Either e x
    m = Left e

g :: Show a => [a] -> String
g ((x :: a) : _) = show (y :: a) where y = x
g [] = ""

main :: IO ()
main = print (f (Left "err" :: Either String Int), f (Right 3 :: Either String Int), g [True])
