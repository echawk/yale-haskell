-- Control.Applicative (base), for Yale Haskell's Haskell 98 dialect: the
-- classes are PreludeModern's (doc/plans/MICROCABAL.md step 2).
module Control.Applicative (
    Applicative(pure, (<*>), (*>), (<*)), Alternative(empty, (<|>), some, many),
    (<$>), (<$), (<**>), liftA, liftA2, liftA3, optional
  ) where

import PreludeModern
