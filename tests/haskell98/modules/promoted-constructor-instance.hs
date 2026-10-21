{-# LANGUAGE DataKinds #-}
-- An instance at a promoted constructor of another module ('MD, which the
-- defining module's DataKinds promotes unticked too) and at 'True
module Main (main) where
import PromotedConstructorInstanceA
main :: IO ()
main = putStrLn (x (P :: P 'True)) >> putStrLn (x (P :: P ('MD 'True 'False)))
