module Example.ExternalComponents.Spec where

import Prelude

import Data.List.NonEmpty (singleton)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.Symbol (SProxy(..))
import Data.Validation.Semigroup (V, invalid)
import Example.Validation.Semigroup as V
import Formless.Spec as FSpec
import Formless.Validation (onInputField)
import Type.Row (RProxy(..))

-- | You must provide a newtype around your form record in this format. Here,
-- | rather than a record accepting `f`, we're just providing a row.
newtype Form f = Form (Record (FormRow f))
derive instance newtypeForm :: Newtype (Form f) _

-- | We'll use this row to generate our form spec, but also to represent the
-- | available fields in the record.
type FormRow f =
  ( name     :: f String         V.Errs String
  , email    :: f (Maybe String) V.Errs String
  , whiskey  :: f (Maybe String) V.Errs String
  , language :: f (Maybe String) V.Errs String
  )

-- | You'll usually want symbol proxies for convenience
_name = SProxy :: SProxy "name"
_email = SProxy :: SProxy "email"
_whiskey = SProxy :: SProxy "whiskey"
_language = SProxy :: SProxy "language"

-- | mkFormSpecFromRow can produce a valid input form spec from your row
-- | without you having to type anything. This is useful for especially
-- | large forms where you don't want to have to stick newtypes everywhere.
-- | If you already have a record of values, use `mkFormSpec` instead.
formSpec :: Form FSpec.FormSpec
formSpec = FSpec.mkFormSpecFromRow $ RProxy :: RProxy (FormRow FSpec.Input)

-- | You should provide your own validation. This example uses the PureScript
-- | standard, `purescript-validation`.
formValidation :: Form FSpec.InputField -> Form FSpec.InputField
formValidation (Form form) = Form
  { name: (\i -> V.validateNonEmpty i *> V.validateMinimumLength i 7) `onInputField` form.name
  , email: (\i -> validateMaybe i *> V.validateEmailRegex (fromMaybe "" i)) `onInputField` form.email
  , whiskey: validateMaybe `onInputField` form.whiskey
  , language: validateMaybe `onInputField` form.language
  }

-- | A custom validator that verifies a value is not Nothing
validateMaybe :: ∀ a. Maybe a -> V V.Errs a
validateMaybe Nothing = invalid (singleton V.EmptyField)
validateMaybe (Just a) = pure a

