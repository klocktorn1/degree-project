module Route exposing (ExercisesRoute(..), Route(..), fromUrl)

import Url
import Url.Parser as UP exposing ((</>))


type Route
    = Home
    | Exercises ExercisesRoute
    | Login
    | Register
    | Dashboard
    | NotFound


type ExercisesRoute
    = ExercisesHome
    | ChordGuesserRoute


parser : UP.Parser (Route -> a) a
parser =
    UP.oneOf
        [ UP.map Home UP.top
        , UP.map Login (UP.s "login")
        , UP.map Register (UP.s "register")
        , UP.map Dashboard (UP.s "dashboard")
        , UP.map (Exercises ExercisesHome) (UP.s "all-exercises")
        , UP.map (Exercises ChordGuesserRoute)
            (UP.s "all-exercises" </> UP.s "chord-guesser")
        ]


fromUrl : Url.Url -> Route
fromUrl url =
    UP.parse parser url
        |> Maybe.withDefault NotFound
