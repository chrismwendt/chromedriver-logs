{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE MultiWayIf #-}

module Main where

import Streaming
import qualified Streaming.Prelude as S
import Data.Aeson
import qualified Data.ByteString.Char8 as BS8
import qualified Data.ByteString.Lazy.Char8 as BS8L
import qualified Data.ByteString.Streaming.Char8 as Q
import qualified Data.Attoparsec.ByteString.Char8 as A
import qualified Data.Attoparsec.ByteString.Streaming as A
import qualified Data.Attoparsec.Combinator as A
import qualified Data.Text as T
import Data.Function ((&))
import GHC.Generics
import qualified Data.Map as M
import Data.IORef
import Data.Scientific
import System.IO

main :: IO ()
main = do
  hSetBuffering stdin LineBuffering
  hSetBuffering stdout LineBuffering
  -- I used an IORef to store the in-flight commands. StateT is a potential alternative.
  inFlightCommands <- newIORef M.empty
  let
    addCommand i theMsg = modifyIORef inFlightCommands (M.insert i theMsg)
    getCommand i = M.lookup i <$> readIORef inFlightCommands

  Q.getContents
    -- ignore junk lines
    & A.parsed (Just <$> messageP <|> Nothing <$ anyTill A.endOfLine)
    & S.concat -- like catMaybes
    & S.mapM (\msg -> case metadata msg of
        None -> return msg
        Command i -> addCommand i msg >> return msg
        Response i _ -> do
          cmd <- getCommand i
          return $ msg { metadata = Response i cmd })
    & S.mapM_ (putStrLn . BS8L.unpack . encode)
    & void -- ignore return value

anyTill :: A.Parser a -> A.Parser String
anyTill p = A.manyTill A.anyChar p

data Message = Message
  { timestamp :: Scientific
  , logLevel :: T.Text
  , message :: T.Text
  , metadata :: Metadata
  } deriving (Generic)

data Metadata =
    None
  | Command Int
  | Response Int (Maybe Message)

instance ToJSON Message
instance ToJSON Metadata where
  toJSON None = Null
  toJSON (Command i) = object ["id" .= i]
  toJSON (Response i initiatingCommand) = object
    [ "id" .= i
    , "initiatingCommand" .= initiatingCommand
    ]

messageP :: A.Parser Message
messageP = do
  timestamp_ <- "[" *> A.scientific <* "]"
  logLevel_ <- "[" *> A.many1 A.letter_ascii <* "]"
  void $ ": "
  message_ <- anyTill (A.lookAhead $ A.endOfLine >> "[")
  A.endOfLine

  let
    metadata_ = either (const None) id $
      flip A.parseOnly (BS8.pack message_) $
      A.choice
      [ Command <$> (anyTill "COMMAND" *> anyTill "(id=" *> A.decimal <* ")")
      , Response <$> (anyTill "RESPONSE" *> anyTill "(id=" *> A.decimal <* ")") <*> pure Nothing
      ]

  return $ Message
    { timestamp = timestamp_
    , logLevel = T.pack logLevel_
    , message = T.pack message_
    , metadata = metadata_
    }