module Pages.Exercises exposing (Model, Msg, init, subscriptions, update, view)

import Exercises.ChordGuesserExercise as ChordGuesserExercise
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Platform.Cmd exposing (Cmd)
import Platform.Sub exposing (Sub)


type alias Model =
    { chordGuesserModel : ChordGuesserExercise.Model
    , currentGame : Maybe Game
    }


type Game
    = ChordGuesser


type Msg
    = ChordGuesserMsg ChordGuesserExercise.Msg
    | SelectGame Game
    | BackToList


type alias Flags =
    String


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( chordModel, chordCmd ) =
            ChordGuesserExercise.init flags
    in
    ( { chordGuesserModel = chordModel, currentGame = Nothing }
    , Cmd.map ChordGuesserMsg chordCmd
    )



-- expose an initialFetch to be used by top-level Main when entering /exercises


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChordGuesserMsg sub ->
            let
                ( updated, cmd ) =
                    ChordGuesserExercise.update sub model.chordGuesserModel
            in
            ( { model | chordGuesserModel = updated }, Cmd.map ChordGuesserMsg cmd )

        SelectGame game ->
            ( { model | currentGame = Just game }, Cmd.none )

        BackToList ->
            ( { model | currentGame = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.currentGame of
        Just ChordGuesser ->
            Html.div []
                [ Html.button [ HA.class "custom-button", HE.onClick BackToList ] [ Html.text "< Back" ]
                , Html.map ChordGuesserMsg (ChordGuesserExercise.view model.chordGuesserModel)
                ]

        Nothing ->
            Html.div []
                [ Html.h2 [] [ Html.text "Exercises" ]
                , Html.ul []
                    [ Html.li []
                        [ Html.button
                            [ HE.onClick (SelectGame ChordGuesser), HA.class "custom-button" ]
                            [ Html.text "Chord Guesser" ]
                        ]
                    ]
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ChordGuesserMsg (ChordGuesserExercise.subscriptions model.chordGuesserModel)
