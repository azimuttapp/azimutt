module PagesComponents.Blog.Models exposing (Model)

import Components.Slices.Blog exposing (Article)


type alias Model =
    { articles : List Article }
