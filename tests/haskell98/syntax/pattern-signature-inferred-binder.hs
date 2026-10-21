{-# LANGUAGE PatternSynonyms, ViewPatterns, GADTs, PolyKinds, ScopedTypeVariables #-}
newtype N z s n = N Int

data Res z s n where
  RZ :: Res z s z
  RS :: N z s n -> Res z s (s n)

check :: N z s n -> Res z s n
check (N 0) = unsafeRes RZ
check (N n) = unsafeRes (RS (N (n - 1)))

unsafeRes :: Res z s m -> Res z s n
unsafeRes r = case r of { RZ -> error "x"; _ -> error "y" }

pattern Zeroy :: forall {k} z s (n :: k). () => n ~ z => N z s n
pattern Zeroy <- (check -> RZ)
  where Zeroy = N 0
{-# INLINE Zeroy #-}

main :: IO ()
main = case (N 0 :: N Int Maybe Int) of { N k -> print k }
