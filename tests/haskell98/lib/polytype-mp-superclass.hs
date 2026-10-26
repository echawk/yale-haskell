-- A rank-2 field's multi-parameter context gives its superclasses
-- (texmath's forall st m s. Stream s m Char => ParsecT s st m Text,
-- Monad m).
{-# LANGUAGE RankNTypes, FlexibleContexts #-}
import Text.Parsec
data M = M { mp :: forall st m s . Stream s m Char => ParsecT s st m String }
mk :: Int -> M
mk n = M (count n anyChar)
main = print (parse (mp (mk 2)) "" "abc")
