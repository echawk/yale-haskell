{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
data K
class Tr arr t where tr :: arr -> t -> String
instance Tr K Int where tr _ n = "K" ++ show n

class Tr_ t where tr_ :: t -> String
instance Tr K t => Tr_ t where tr_ = tr (undefined :: K)

main :: IO ()
main = putStrLn (tr_ (3 :: Int))
