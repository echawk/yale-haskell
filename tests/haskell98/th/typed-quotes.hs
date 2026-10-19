-- Typed Template Haskell: [|| ||] quotes, $$( ) splices, liftTyped.
{-# LANGUAGE TemplateHaskell #-}
import Language.Haskell.TH
import Language.Haskell.TH.Syntax
import TTHGen

main :: IO ()
main = do
  print ($$(power 3) 2)
  print ($$(safeDiv 10) :: Int)
  print $$(liftTyped 'x')
