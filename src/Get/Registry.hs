{-# LANGUAGE OverloadedStrings #-}
module Get.Registry where

import Control.Monad.Error
import qualified Data.Aeson as Json
import qualified Data.Binary as Binary
import Data.Version (showVersion)
import Network.HTTP
import Network.HTTP.Client
import Network.HTTP.Client.MultipartFormData

import qualified Package.Description as Package
import qualified Package.Name as N
import qualified Package.Paths as P
import qualified Package.Version as V
import qualified Paths_elm_package as This

import qualified Utils.Http as Http

domain = "http://library.elm-lang.org"

libraryUrl path vars =
    domain ++ "/" ++ path ++ "?" ++ urlEncodeVars (version : vars)
  where
    version = ("elm-get-version", showVersion This.version)

metadata :: N.Name -> ErrorT String IO (Maybe Package.Description)
metadata name =
    Http.send url $ \request manager ->
    do response <- httpLbs request manager
       return $ Json.decode $ responseBody response
    where
      url = libraryUrl "metadata" [("library", show name)]

versions :: N.Name -> ErrorT String IO (Maybe [V.Version])
versions name =
    Http.send url $ \request manager ->
    do response <- httpLbs request manager
       return $ Binary.decode $ responseBody response
    where
      url = libraryUrl "versions" [("library", show name)]

register :: N.Name -> V.Version -> FilePath -> ErrorT String IO ()
register name version path =
    Http.send url $ \request manager ->
    do request' <- formDataBody files request
       let request'' = request' { responseTimeout = Nothing }
       httpLbs request'' manager
       return ()
    where
      url = libraryUrl "register" vars
      vars = [ ("library", show name), ("version", show version) ]
      files = [ partFileSource "docs" path
              , partFileSource "deps" P.description
              ]
