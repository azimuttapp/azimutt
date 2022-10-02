module Libs.Either exposing (reduce)

import Either exposing (Either(..))


reduce : (a -> c) -> (b -> c) -> Either a b -> c
reduce f g e =
    case e of
        Left a ->
            f a

        Right b ->
            g b
