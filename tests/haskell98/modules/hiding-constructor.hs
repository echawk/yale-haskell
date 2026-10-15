-- A hiding list may name a data constructor (H98 5.3.4).
import HideConA hiding (Success)
import HideConB
main = print (Success True, Failure "x")
