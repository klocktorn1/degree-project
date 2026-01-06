module Pages.Exercises exposing (..)

import Exercises.ChordGuesserExercise as ChordGuesserExercise
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Platform.Cmd exposing (Cmd)
import Platform.Sub exposing (Sub)
import Route exposing (ExercisesRoute(..), Route(..))


type alias Model =
    { chordGuesserModel : ChordGuesserExercise.Model
    , currentGame : Maybe Game
    }


type Game
    = ChordGuesser


type Msg
    = ChordGuesserMsg ChordGuesserExercise.Msg
    | BackToList
    | RequestNavigateToChordGuesser


init : ExercisesRoute -> ( Model, Cmd Msg )
init route =
    let
        ( chordModel, chordCmd ) =
            ChordGuesserExercise.init ()

        currentGame =
            case route of
                ChordGuesserRoute ->
                    Just ChordGuesser

                ExercisesHome ->
                    Nothing
    in
    ( { chordGuesserModel = chordModel, currentGame = currentGame }
    , Cmd.batch [ Cmd.map ChordGuesserMsg chordCmd ]
    )



-- expose an initialFetch to be used by top-level Main when entering /exercises


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChordGuesserMsg subMsg ->
            case subMsg of
                ChordGuesserExercise.BackToList ->
                    ( { model | currentGame = Nothing }, Cmd.none )

                _ ->
                    let
                        ( updated, cmd ) =
                            ChordGuesserExercise.update subMsg model.chordGuesserModel
                    in
                    ( { model | chordGuesserModel = updated }
                    , Cmd.map ChordGuesserMsg cmd
                    )

        BackToList ->
            ( { model | currentGame = Nothing }, Cmd.none )

        RequestNavigateToChordGuesser ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.currentGame of
        Just ChordGuesser ->
            Html.map ChordGuesserMsg (ChordGuesserExercise.view model.chordGuesserModel)

        Nothing ->
            Html.section [HA.class "nes-container is-rounded"]
                [ Html.h1 [] [ Html.text "Exercises" ]
                , Html.ul [ HA.class "card-grid" ]
                    [ Html.li [ HA.class "card" ]
                        [ Html.div
                            [ HE.onClick RequestNavigateToChordGuesser, HA.class "card-data" ]
                            [ Html.img [ HA.src "../assets/img/guitar3.png", HA.alt "guitar" ] []
                            , Html.p [] [ Html.text "Chord Guesser" ]
                            ]
                        ]
                    , Html.li [ HA.class "card" ]
                        [ Html.div
                            [ HE.onClick RequestNavigateToChordGuesser, HA.class "card-data" ]
                            [ Html.img [ HA.src "../assets/img/guitar3.png", HA.alt "guitar" ] []
                            , Html.p [] [ Html.text "Chord Guesser" ]
                            ]
                        ]
                    , Html.li [ HA.class "card" ]
                        [ Html.div
                            [ HE.onClick RequestNavigateToChordGuesser, HA.class "card-data" ]
                            [ Html.img [ HA.src "../assets/img/guitar3.png", HA.alt "guitar" ] []
                            , Html.p [] [ Html.text "Chord Guesser" ]
                            ]
                        ]
                    ]
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ChordGuesserMsg (ChordGuesserExercise.subscriptions model.chordGuesserModel)
