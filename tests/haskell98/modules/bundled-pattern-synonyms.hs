-- Pattern synonyms bundled with a type (T (.., P), T (P)), re-exported,
-- operator synonyms used infix (containers' Seq (Empty, (:<|), (:|>))).
{-# LANGUAGE PatternSynonyms #-}
import BundleB
f :: Q Int -> String
f Nil = "nil"
f (x :> _) = "head " ++ show x
main = putStrLn (f (fromL [3, 4])) >> putStrLn (f (fromL []))
