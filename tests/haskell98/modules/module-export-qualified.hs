-- ReExp imports AmbB only qualified, so `module ...' exports nothing of
-- it: onlyB is not in scope here.
import ReExp

main :: IO ()
main = print onlyB
