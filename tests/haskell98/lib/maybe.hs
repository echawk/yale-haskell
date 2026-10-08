-- The Maybe library.
module Main where
import Dialogue (stdout, appendChan, done, abort)

import Maybe

main = appendChan stdout (unlines [
  show (isJust (Just 'a'), isJust (Nothing :: Maybe Int), isNothing (Nothing :: Maybe ())),
  show (fromJust (Just 3 :: Maybe Int), fromMaybe 0 Nothing, fromMaybe 0 (Just (5 :: Int))),
  show (listToMaybe [1, 2, 3 :: Int], listToMaybe "", maybeToList (Just 'q'), maybeToList (Nothing :: Maybe Int)),
  show (catMaybes [Just 1, Nothing, Just (3 :: Int)]),
  show (mapMaybe (\x -> if x > 2 then Just (x * x) else Nothing) [1 .. 5 :: Int]),
  show (maybe "none" show (Just (7 :: Int)))
  ]) abort done
