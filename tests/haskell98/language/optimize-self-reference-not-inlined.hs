-- nhc98's FixSyntax.makeTypeRep: its unused local foldAp, whose one
-- reference is its own call, was inlined into itself at every optimizer
-- pass (doubling: 637 nodes to 574,089), and the compile ran out of memory
module Main where

data NT = NTvar Int Int | NTapp NT NT | NTstrict NT | NTcons Int Int [NT]
        | NTexist Int Int | NTany Int
data Lit = LitString String deriving Show
data Exp = ExpApplication Int [Exp] | ExpLit Int Lit | ExpCon String deriving Show

lookupIS :: [(Int, String)] -> Int -> Maybe String
lookupIS st i = lookup i st

strIS :: [(Int, String)] -> Int -> String
strIS st i = maybe "?" id (lookup i st)

makeTypeRep :: Int -> (Exp, Exp, Exp, Exp) -> [(Int, String)] -> NT -> Exp
makeTypeRep pos (eNil,eCons,eTyCon,eTyGen) state nt = rep (deTypeType nt)
    where
    deTypeType (NTcons _ _ [t]) = t

    rep (NTvar i kind) =
         case lookupIS state i of
            Just info -> tyCon (show info) []
            Nothing   -> tyGen $ 'v':(show i)
    rep (NTapp x y) =  app (rep x) (rep y)
    rep (NTstrict _) = error "rep: NTstrict"
    rep (NTcons i k xs) =
        let iStr = strIS state i
        in tyCon iStr (map rep xs)
    rep (NTexist _ _) = error "rep: NTexists"
    rep (NTany _)      = error "rep: NTany"
    rep _           = error "rep: ???"

    foldAp [nt]   = rep nt
    foldAp (x:xs) =
        let xs' = foldAp xs
        in app (rep x) xs'

    app x y = ExpApplication pos [eTyCon, string "Prelude.->", list [x, y]]
    tyCon s ts = ExpApplication pos [eTyCon, string s, list ts]
    tyGen s = ExpApplication pos [eTyGen, string s]
    string s = ExpLit pos (LitString s)

    list []     = eNil
    list (x:xs) = ExpApplication pos [eCons, x, list xs]

main :: IO ()
main = print (makeTypeRep 0 (ExpCon "nil", ExpCon "cons", ExpCon "tc", ExpCon "tg")
                [(1, "Int")] (NTcons 0 0 [NTapp (NTvar 1 0) (NTcons 2 0 [NTvar 3 0])]))
