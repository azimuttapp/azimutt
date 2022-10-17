module Services.Sort exposing (lastUpdatedFirst)

import Time


lastUpdatedFirst : List { a | updatedAt : Time.Posix } -> List { a | updatedAt : Time.Posix }
lastUpdatedFirst projects =
    projects |> List.sortBy (\p -> -(Time.posixToMillis p.updatedAt))
