-- module M exports (report 5.2): `module AmbA' re-exports AmbA's names,
-- `module N' those of the import aliased N; AmbB is imported only
-- qualified, so nothing of it is re-exported.
module ReExp (module AmbA, module N) where
import AmbA
import qualified AmbB
import AmbC as N
