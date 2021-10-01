module PagesComponents.Blog.Slug.Models exposing (Author, Content, Model(..), authors, loic, samir)

import Dict
import Http
import Libs.Nel exposing (Nel)
import Time


type Model
    = Loading
    | BadSlug Http.Error
    | BadContent (Nel String)
    | Loaded Content


type alias Content =
    { title : String
    , excerpt : String
    , category : Maybe String
    , tags : List String
    , author : Author
    , published : Time.Posix
    , body : String
    }


type alias Author =
    { firstName : String
    , lastName : String
    , twitter : Maybe String
    , github : Maybe String
    }


loic : Author
loic =
    { firstName = "Loïc"
    , lastName = "Knuchel"
    , twitter = Just "loicknuchel"
    , github = Just "loicknuchel"
    }


samir : Author
samir =
    { firstName = "Samir"
    , lastName = "Bouaked"
    , twitter = Just "sbouaked"
    , github = Just "sbouaked"
    }


authors : Dict.Dict String Author
authors =
    Dict.fromList
        [ ( "loic", loic )
        , ( "samir", samir )
        ]
