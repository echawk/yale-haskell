-- Control.Category (base)
module Control.Category (Category(id, (.)), (<<<), (>>>)) where

import Prelude hiding (id, (.))
import qualified Prelude as P

infixr 9 .
infixr 1 >>>, <<<

class Category cat where
  id :: cat a a
  (.) :: cat b c -> cat a b -> cat a c

instance Category (->) where
  id = P.id
  (.) = (P..)

(<<<) :: Category cat => cat b c -> cat a b -> cat a c
(<<<) = (.)

(>>>) :: Category cat => cat a b -> cat b c -> cat a c
f >>> g = g . f
