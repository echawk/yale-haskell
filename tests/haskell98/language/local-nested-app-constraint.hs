-- A local binding's constraint on a type with an application of its own type
-- variable inside (Outputable (Located (body Name)): GHC's tcMatch's tc_match)
-- is a flexible one it is generalized over.
{-# LANGUAGE FlexibleContexts #-}
data Name = Name deriving Show
newtype Box a = Box a deriving Show
data Located e = L Int e

class Outputable a where ppr :: a -> String
instance Outputable Name where ppr _ = "Name"
instance Outputable a => Outputable (Box a) where ppr (Box a) = "Box " ++ ppr a
instance Outputable e => Outputable (Located e) where ppr (L _ e) = ppr e

data Match body = Match [Int] body
data Ctxt body = Ctxt { mc_what :: String, mc_body :: body Name -> String }

pprMatch :: Outputable body => String -> Match body -> String
pprMatch c (Match _ b) = c ++ ppr b

tcMatch :: Outputable (body Name) => Ctxt body -> Int -> Match (Located (body Name)) -> String
tcMatch ctxt n match = tc ctxt n match
  where
    tc ctxt n m@(Match _ (L _ b)) = add_ctxt m (show n ++ mc_body ctxt b)
    add_ctxt m thing = case mc_what ctxt of
      "" -> thing
      c -> pprMatch c m ++ ": " ++ thing

main = putStrLn (tcMatch (Ctxt "in " (const "!")) 3 (Match [] (L 0 (Box Name))))
