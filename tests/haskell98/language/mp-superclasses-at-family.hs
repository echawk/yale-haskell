{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, UndecidableInstances, UndecidableSuperClasses, TypeFamilies #-}
data K
data E

class Tr arr t where tr :: arr -> t -> String
instance Tr K Int where tr _ n = "K" ++ show n
instance Tr E Int where tr _ n = "E" ++ show n

class (Tr K t, Tr E t) => Tr_ t
instance (Tr K t, Tr E t) => Tr_ t
class Tr_ t => Trav t
instance Tr_ t => Trav t

type family Rep a
type instance Rep Bool = Int

both :: Trav (Rep a) => a -> Rep a -> String
both _ x = tr (undefined :: K) x ++ tr (undefined :: E) x

main :: IO ()
main = putStrLn (both True 4)
