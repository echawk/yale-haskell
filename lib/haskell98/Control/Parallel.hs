-- Control.Parallel (the parallel package): par sparks its first argument
-- for evaluation in parallel (by a pool of worker threads, with +RTS -N
-- and more than one capability, as GHC's threaded runtime; otherwise it
-- does nothing), and pseq evaluates its first argument before its
-- second.  See src/base/parallel-runtime.lisp.
module Control.Parallel (par, pseq) where

import ParallelPrims (primPar)
import PreludeBltinArray (strict1)

infixr 0 `par`, `pseq`

par :: a -> b -> b
par a b = primPar a b

pseq :: a -> b -> b
pseq a b = strict1 a b
