module Test.Main where

import Prelude

import Data.Array as Array
import Data.String as String
import Data.Traversable (traverse)
import Effect (Effect)
import Effect.Aff (Aff, error, launchAff_, throwError)
import Effect.Class.Console (log)
import FormatNix (TreeSitterParser, children, mkParser, nixLanguage, parse, printExpr, readNode, rootNode)
import Node.Encoding (Encoding(..))
import Node.FS.Aff (readTextFile, writeTextFile)
import Node.Path (FilePath)

parser :: TreeSitterParser
parser = mkParser nixLanguage

processInput :: FilePath -> Aff String
processInput filepath = do
  input <- readTextFile UTF8 filepath
  let node = rootNode $ parse parser input
  let nodes = readNode <$> children node
  log $ "printing " <> filepath <> ":"
  let output = Array.intercalate "\n" $ printExpr <$> nodes
  log output
  log ""
  pure output

main :: Effect Unit
main = launchAff_ do
  results <- traverse processInput
    [ "test/build.nix"
    , "test/import.nix"
    , "test/signs.nix"
    , "test/inherits.nix"
    , "test/fetch-github.nix"
    ]
  let output = Array.intercalate "\n\n" results
  writeTextFile UTF8 "test/output.nix" output
  if String.contains (String.Pattern "Unknown") output
    then throwError $ error "contained Unknowns"
    else pure unit
