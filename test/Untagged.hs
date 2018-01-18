{-# LANGUAGE QuasiQuotes, OverloadedStrings, TemplateHaskell, RecordWildCards, ScopedTypeVariables, NamedFieldPuns #-}

module Untagged (tests) where

import Data.Aeson as A
import Data.Aeson.TH as A
import Data.Aeson.TypeScript.TH
import Data.Monoid
import Data.Proxy
import Data.String.Interpolate.IsString
import Prelude hiding (Double)
import System.IO.Unsafe (unsafePerformIO)
import Test.Hspec
import Test.Tasty
import Test.Tasty.Hspec (testSpec)
import Test.Tasty.Runners
import Util


data Unit = Unit
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''Unit)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''Unit)

data OneFieldRecordless = OneFieldRecordless Int
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''OneFieldRecordless)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''OneFieldRecordless)

data OneField = OneField { simpleString :: String }
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''OneField)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''OneField)

data TwoFieldRecordless = TwoFieldRecordless Int String
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoFieldRecordless)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoFieldRecordless)

data TwoField = TwoField { doubleInt :: Int
                         , doubleString :: String }
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoField)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoField)

data TwoConstructor = Con1 { con1String :: String }
                    | Con2 { con2String :: String
                           , con2Int :: Int }
$(deriveJSON (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoConstructor)
$(deriveTypeScript (A.defaultOptions {sumEncoding=UntaggedValue}) ''TwoConstructor)


tests = unsafePerformIO $ testSpec "UntaggedValue" $ do
  describe "single constructor" $ do
    it [i|with a single nullary constructor like #{A.encode Unit}|] $ do
      (getTypeScriptType (Proxy :: Proxy Unit)) `shouldBe` "Unit"
      (getTypeScriptDeclaration (Proxy :: Proxy Unit)) `shouldBe` ([
        TSTypeAlternatives "Unit" [] ["void[]"]
        ])

    it [i|with a single non-record constructor like #{A.encode $ OneFieldRecordless 42}|] $ do
      (getTypeScriptType (Proxy :: Proxy OneFieldRecordless)) `shouldBe` "OneFieldRecordless"
      (getTypeScriptDeclaration (Proxy :: Proxy OneFieldRecordless)) `shouldBe` ([
        TSTypeAlternatives "OneFieldRecordless" [] ["number"]
        ])

    it [i|with a single record constructor like #{A.encode $ OneField "asdf"}|] $ do
      (getTypeScriptType (Proxy :: Proxy OneField)) `shouldBe` "OneField"
      (getTypeScriptDeclaration (Proxy :: Proxy OneField)) `shouldBe` ([
        TSTypeAlternatives "OneField" [] ["IOneField"],
        TSInterfaceDeclaration "IOneField" [] [TSField False "simpleString" "string"]
        ])

    it [i|with a two-field non-record constructor like #{A.encode $ TwoFieldRecordless 42 "asdf"}|] $ do
      (getTypeScriptType (Proxy :: Proxy TwoFieldRecordless)) `shouldBe` "TwoFieldRecordless"
      (getTypeScriptDeclaration (Proxy :: Proxy TwoFieldRecordless)) `shouldBe` ([
        TSTypeAlternatives "TwoFieldRecordless" [] ["[number, string]"]
        ])

    it [i|with a two-field record constructor like #{A.encode $ TwoField 42 "asdf"}|] $ do
      (getTypeScriptType (Proxy :: Proxy TwoField)) `shouldBe` "TwoField"
      (getTypeScriptDeclaration (Proxy :: Proxy TwoField)) `shouldBe` ([
        TSTypeAlternatives "TwoField" [] ["ITwoField"],
        TSInterfaceDeclaration "ITwoField" [] [TSField False "doubleInt" "number",
                                               TSField False "doubleString" "string"]
        ])

    it [i|with a two-constructor type like #{A.encode $ Con1 "asdf"} or #{A.encode $ Con2 "asdf" 42}|] $ do
      (getTypeScriptType (Proxy :: Proxy TwoConstructor)) `shouldBe` "TwoConstructor"
      (getTypeScriptDeclaration (Proxy :: Proxy TwoConstructor)) `shouldBe` ([
        TSTypeAlternatives "TwoConstructor" [] ["ICon1","ICon2"],
        TSInterfaceDeclaration "ICon1" [] [TSField False "con1String" "string"],
        TSInterfaceDeclaration "ICon2" [] [TSField False "con2String" "string",
                                           TSField False "con2Int" "number"]
        ])

    it "type checks everything with tsc" $ do
      let declarations = ((getTypeScriptDeclaration (Proxy :: Proxy Unit)) <>
                          (getTypeScriptDeclaration (Proxy :: Proxy OneFieldRecordless)) <>
                          (getTypeScriptDeclaration (Proxy :: Proxy OneField)) <>
                          (getTypeScriptDeclaration (Proxy :: Proxy TwoFieldRecordless)) <>
                          (getTypeScriptDeclaration (Proxy :: Proxy TwoField)) <>
                          (getTypeScriptDeclaration (Proxy :: Proxy TwoConstructor))
                         )

      let typesAndValues = [(getTypeScriptType (Proxy :: Proxy Unit) , A.encode Unit)
                           , (getTypeScriptType (Proxy :: Proxy OneFieldRecordless) , A.encode $ OneFieldRecordless 42)
                           , (getTypeScriptType (Proxy :: Proxy OneField) , A.encode $ OneField "asdf")
                           , (getTypeScriptType (Proxy :: Proxy TwoFieldRecordless) , A.encode $ TwoFieldRecordless 42 "asdf")
                           , (getTypeScriptType (Proxy :: Proxy TwoField) , A.encode $ TwoField 42 "asdf")
                           , (getTypeScriptType (Proxy :: Proxy TwoConstructor) , A.encode $ Con1 "asdf")
                           , (getTypeScriptType (Proxy :: Proxy TwoConstructor) , A.encode $ Con2 "asdf" 42)
                           ]

      testTypeCheckDeclarations declarations typesAndValues


main = defaultMainWithIngredients defaultIngredients tests