-- GHC.Fingerprint: MD5, the digest's halves big-endian (md5 of "",
-- of "abc" as four bytes a character, of 16 zero bytes)
import GHC.Fingerprint
main = do
  print (fingerprintString "")
  print (fingerprintString "abc")
  print (fingerprintFingerprints [fingerprint0])
