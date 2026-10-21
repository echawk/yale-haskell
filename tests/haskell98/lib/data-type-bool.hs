{-# LANGUAGE DataKinds, TypeFamilies, TypeOperators, KindSignatures #-}
import Data.Type.Bool

class Val (b :: Bool) where val :: proxy b -> Bool
instance Val 'True where val _ = True
instance Val 'False where val _ = False

data P (b :: Bool) = P

main :: IO ()
main = print ( val (P :: P (If 'True 'False 'True))
             , val (P :: P ('True && Not 'False))
             , val (P :: P ('False || 'False)) )
