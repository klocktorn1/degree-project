module Exercises.ChordGuesserExercise exposing (..)

import Db.Exercises as Exercises
import Db.TheoryApi as TheoryApi
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode
import List.Extra as ListExtra
import Random
import Random.List as RandomList
import String


type alias Model =
    { maybeChords : Maybe (List TheoryApi.Chord)
    , isGameStarted : Bool
    , chosenDifficulty : Difficulty
    , pendingFetches : Int
    , rootNotes : List String
    , maybeChosenChord : Maybe TheoryApi.Chord
    , randomizedChord : Maybe TheoryApi.Chord
    , randomizedChordNotes : Maybe (List String)
    , lastRandomIndex : Maybe Int
    , areNotesShuffled : Bool
    , score : Int
    , mistakes : Int
    , gameOver : Bool
    , subExercises : Maybe (List Exercises.SubExercise)
    , completedSubExercises : Maybe Exercises.CompletedSubExercises
    , chosenSubExercise : Maybe Exercises.SubExercise
    , error : Maybe String
    , hasUserWon : Bool
    }


type Msg
    = GotChordData (Result Http.Error (List TheoryApi.Chord))
    | GotSubExercises (Result Http.Error (List Exercises.SubExercise))
    | GotCompletedSubExercises (Result Http.Error Exercises.CompletedSubExercises)
    | CompletedExerciseEntryResponse (Result Http.Error Exercises.CompletedResponse)
    | RandomChordPicked Int
    | DifficultyChosen Difficulty
    | ChordChosen TheoryApi.Chord
    | ChordGroupChosen Exercises.SubExercise
    | Shuffled (List String)
    | ToggleNotesShuffle
    | GoBack


type Difficulty
    = Easy
    | Medium
    | Hard
    | Advanced
    | Extreme


init : () -> ( Model, Cmd Msg )
init _ =
    ( { maybeChords = Nothing
      , maybeChosenChord = Nothing
      , isGameStarted = False
      , chosenDifficulty = Easy
      , pendingFetches = 0
      , rootNotes = [ "C", "G", "F" ]
      , randomizedChord = Nothing
      , randomizedChordNotes = Nothing
      , lastRandomIndex = Nothing
      , areNotesShuffled = False
      , score = 0
      , mistakes = 0
      , gameOver = False
      , subExercises = Nothing
      , error = Nothing
      , completedSubExercises = Nothing
      , hasUserWon = False
      , chosenSubExercise = Nothing
      }
    , Cmd.batch [ Exercises.fetchCompletedExercises GotCompletedSubExercises, fetchSubExercisesCmd ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotChordData (Ok chords) ->
            let
                existingChords =
                    Maybe.withDefault [] model.maybeChords

                combined =
                    existingChords ++ chords

                remaining =
                    model.pendingFetches - 1

                chordCount =
                    List.length combined

                cmd =
                    if remaining <= 0 && chordCount > 0 then
                        randomizeChord chordCount

                    else
                        Cmd.none
            in
            ( { model | maybeChords = Just combined, pendingFetches = remaining }, cmd )

        GotChordData (Err _) ->
            let
                remaining =
                    model.pendingFetches - 1

                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                cmd =
                    if remaining <= 0 && chordCount > 0 then
                        randomizeChord chordCount

                    else
                        Cmd.none
            in
            ( { model | pendingFetches = remaining }, cmd )

        GotCompletedSubExercises (Ok response) ->
            ( { model | completedSubExercises = Just response }, Cmd.none )

        GotCompletedSubExercises (Err err) ->
            ( { model | error = Just (Exercises.buildErrorMessage err) }, Cmd.none )

        DifficultyChosen difficulty ->
            let
                newDifficulty =
                    difficulty

                areNotesShuffled =
                    case newDifficulty of
                        Easy ->
                            False

                        Medium ->
                            False

                        Hard ->
                            True

                        Advanced ->
                            True

                        Extreme ->
                            True
            in
            ( { model | chosenDifficulty = newDifficulty, rootNotes = setRootNotes newDifficulty, areNotesShuffled = areNotesShuffled }, Cmd.none )

        ChordGroupChosen subExercise ->
            let
                fetchCount =
                    List.length model.rootNotes
            in
            ( { model
                | isGameStarted = True
                , maybeChords = Just []
                , pendingFetches = fetchCount
                , chosenSubExercise = Just subExercise
              }
            , TheoryApi.fetchChords model.rootNotes subExercise.endpoints GotChordData
            )

        Shuffled chordNotes ->
            -- Don't mutate the canonical `randomizedChord` used for equality checks.
            -- Store the shuffled/ display-only notes in `randomizedChordNotes`.
            ( { model | randomizedChordNotes = Just chordNotes }, Cmd.none )

        RandomChordPicked randomIndex ->
            let
                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                -- helper to pick the chord at index or default
                newRandomChord =
                    pickRandomChord model.maybeChords randomIndex

                notes =
                    newRandomChord.notes
            in
            case model.lastRandomIndex of
                Just lastIndex ->
                    if lastIndex == randomIndex && chordCount > 1 then
                        -- avoid same index: try again
                        ( model, randomizeChord chordCount )

                    else
                        ( { model
                            | randomizedChord = Just newRandomChord
                            , lastRandomIndex = Just randomIndex
                            , randomizedChordNotes = Just notes
                          }
                        , shuffleNotesInChord model notes
                        )

                Nothing ->
                    ( { model
                        | randomizedChord = Just newRandomChord
                        , lastRandomIndex = Just randomIndex
                        , randomizedChordNotes = Just notes
                      }
                    , shuffleNotesInChord model notes
                    )

        ToggleNotesShuffle ->
            ( { model | areNotesShuffled = not model.areNotesShuffled }, Cmd.none )

        ChordChosen chord ->
            let
                modelWithChordChosen =
                    { model | maybeChosenChord = Just chord }

                ( updatedModel, cmd ) =
                    checkIfChordIsCorrect modelWithChordChosen
            in
            ( updatedModel, cmd )

        GoBack ->
            let
                updatedModel =
                    { model
                        | isGameStarted = False
                        , maybeChosenChord = Nothing
                        , gameOver = False
                        , hasUserWon = False
                        , mistakes = 0
                        , score = 0
                        , chosenSubExercise = Nothing
                    }
            in
            ( updatedModel, Exercises.fetchCompletedExercises GotCompletedSubExercises )

        GotSubExercises (Ok result) ->
            ( { model | subExercises = Just result }, Cmd.none )

        GotSubExercises (Err error) ->
            ( model, Cmd.none )

        CompletedExerciseEntryResponse (Ok response) ->
            ( model, Cmd.none )

        CompletedExerciseEntryResponse (Err err) ->
            ( model, Cmd.none )


listOfDifficulities : List Difficulty
listOfDifficulities =
    [ Easy, Medium, Hard, Advanced, Extreme ]


fetchSubExercisesCmd : Cmd Msg
fetchSubExercisesCmd =
    Exercises.fetchSubExercises "1" GotSubExercises


difficultyToInt : Difficulty -> Int
difficultyToInt difficulty =
    case difficulty of
        Easy ->
            0

        Medium ->
            1

        Hard ->
            2

        Advanced ->
            3

        Extreme ->
            4


isToggleShuffleDisabled : Difficulty -> Bool
isToggleShuffleDisabled difficulty =
    case difficulty of
        Easy ->
            False

        Medium ->
            False

        Hard ->
            True

        Advanced ->
            True

        Extreme ->
            False


view : Model -> Html Msg
view model =
    if model.isGameStarted then
        if model.hasUserWon then
            Html.div []
                [ Html.text "Good job! "
                , Html.button [ HE.onClick GoBack ] [ Html.text "< Back to exercises" ]
                ]

        else
            Html.div []
                [ Html.text "Chord guesser"
                , viewRandomizedChordNotes model
                , viewChords model
                , Html.p [] [ Html.text <| "Score:  " ++ String.fromInt model.score ++ "/10" ]
                , Html.p [] [ Html.text <| "Mistakes:  " ++ String.fromInt model.mistakes ]
                , Html.text (Debug.toString model.randomizedChord)
                , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text "< Back" ]
                ]

    else
        Html.section []
            [ Html.h2 [] [ Html.text "Chord Guesser Exercise" ]
            , viewDifficultyButtons listOfDifficulities
            , Html.div []
                [ Html.text ("Chosen difficulty: " ++ difficultyToString model.chosenDifficulty)
                ]
            , Html.label [ HA.for "shuffle-notes-checkbox" ] [ Html.text "Shuffle Notes" ]
            , Html.input
                [ HA.type_ "checkbox"
                , HA.checked model.areNotesShuffled
                , HA.id "shuffle-notes-checkbox"
                , HE.onClick ToggleNotesShuffle
                , HA.disabled (isToggleShuffleDisabled model.chosenDifficulty)
                ]
                [ Html.text "Toggle Shuffle Notes" ]
            , Html.div []
                [ viewSubExercises model
                ]
            ]


viewSubExercises : Model -> Html Msg
viewSubExercises model =
    case model.subExercises of
        Just subExercises ->
            Html.ul [] (List.map (viewSubExercise model.chosenDifficulty model.completedSubExercises) subExercises)

        Nothing ->
            Html.p [] [ Html.text "Error" ]


viewSubExercise : Difficulty -> Maybe Exercises.CompletedSubExercises -> Exercises.SubExercise -> Html Msg
viewSubExercise chosenDifficulty maybeCompleted subExercise =
    let
        isCompleted =
            case maybeCompleted of
                Just completed ->
                    checkIfCompleted chosenDifficulty completed.completedSubExercises subExercise

                Nothing ->
                    False
    in
    if isCompleted then
        Html.li [ HE.onClick (ChordGroupChosen subExercise) ]
            [ Html.text subExercise.name
            , Html.span [ HA.class "completed" ] [ Html.text " Completed" ]
            ]

    else
        Html.li [ HE.onClick (ChordGroupChosen subExercise) ]
            [ Html.text subExercise.name
            ]


viewDifficultyButtons : List Difficulty -> Html Msg
viewDifficultyButtons difficulties =
    Html.div []
        (List.map
            (\difficulty ->
                Html.button
                    [ HA.class "custom-button"
                    , HE.onClick (DifficultyChosen difficulty)
                    ]
                    [ Html.text (difficultyToString difficulty) ]
            )
            difficulties
        )


setRootNotes : Difficulty -> List String
setRootNotes difficulty =
    case difficulty of
        Easy ->
            [ "C", "G", "F" ]

        -- Only C, G, F, notes are not shuffled, user can choose to shuffle notes maybe?
        Medium ->
            [ "C", "G", "F", "D", "A" ]

        Hard ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb" ]

        -- Notes are always shuffled
        Advanced ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb", "E", "B", "Ab", "Db" ]

        Extreme ->
            [ "C", "G", "F", "D", "A", "Bb", "Eb", "E", "B", "Ab", "Db", "Fsharp", "Csharp", "Gsharp", "Dsharp", "Asharp" ]


difficultyToString : Difficulty -> String
difficultyToString difficulty =
    case difficulty of
        Easy ->
            "Easy"

        Medium ->
            "Medium"

        Hard ->
            "Hard"

        Advanced ->
            "Advanced"

        Extreme ->
            "Extreme"


viewChords : Model -> Html Msg
viewChords model =
    case model.maybeChords of
        Just chords ->
            Html.div [ HA.class "chords-container" ]
                (List.map viewChord chords)

        Nothing ->
            Html.div [] [ Html.text "No chords found" ]


viewChord : TheoryApi.Chord -> Html Msg
viewChord chord =
    Html.div [ HA.class "custom-button", HE.onClick (ChordChosen chord) ]
        [ Html.text chord.chord ]


viewRandomizedChordNotes : Model -> Html Msg
viewRandomizedChordNotes model =
    case model.randomizedChordNotes of
        Just randomizedChordNotes ->
            Html.p [] [ Html.text ("Which chord is this? " ++ String.join ", " randomizedChordNotes) ]

        Nothing ->
            Html.p [] [ Html.text "No chord found" ]



-- Random.generate Shuffled (RandomList.shuffle notes)


shuffleNotesInChord : Model -> List String -> Cmd Msg
shuffleNotesInChord model notes =
    if model.areNotesShuffled then
        Random.generate Shuffled (RandomList.shuffle notes)

    else
        Cmd.none


defaultChord : TheoryApi.Chord
defaultChord =
    { chord = "No chord found"
    , root = ""
    , formula = []
    , degrees = []
    , notes = []
    }


pickRandomChord : Maybe (List TheoryApi.Chord) -> Int -> TheoryApi.Chord
pickRandomChord maybeChords randomIndex =
    case maybeChords of
        Just chords ->
            case ListExtra.getAt randomIndex chords of
                Just randomChordObject ->
                    randomChordObject

                Nothing ->
                    defaultChord

        Nothing ->
            defaultChord


randomizeChord : Int -> Cmd Msg
randomizeChord maxIndex =
    if maxIndex <= 0 then
        Cmd.none

    else
        Random.generate RandomChordPicked (Random.int 0 (maxIndex - 1))


checkIfChordIsCorrect : Model -> ( Model, Cmd Msg )
checkIfChordIsCorrect model =
    case ( model.maybeChosenChord, model.randomizedChord ) of
        ( Just chosenChord, Just randomizedChord ) ->
            if chosenChord.chord == randomizedChord.chord then
                let
                    newScore =
                        model.score + 1

                    chordCount =
                        List.length (Maybe.withDefault [] model.maybeChords)

                    updatedModel =
                        if newScore == 3 then
                            let
                                cmd =
                                    case model.chosenSubExercise of
                                        Just chosenSubExercise ->
                                            let
                                                body =
                                                    Encode.object
                                                        [ ( "sub_exercise_id", Encode.int chosenSubExercise.id )
                                                        , ( "difficulty", Encode.int (difficultyToInt model.chosenDifficulty) )
                                                        ]
                                            in
                                            Exercises.createCompletedExerciseEntry body CompletedExerciseEntryResponse

                                        Nothing ->
                                            Cmd.none
                            in
                            ( { model | hasUserWon = True }, cmd )

                        else
                            ( { model | score = newScore }, randomizeChord chordCount )
                in
                updatedModel

            else
                let
                    newMistakes =
                        model.mistakes + 1

                    setGameOver =
                        if newMistakes >= 3 then
                            True

                        else
                            False
                in
                ( { model | mistakes = newMistakes, gameOver = setGameOver }, Cmd.none )

        _ ->
            ( model, Cmd.none )


checkIfCompleted : Difficulty -> List Exercises.CompletedSubExercise -> Exercises.SubExercise -> Bool
checkIfCompleted chosenDifficulty completed subExercise =
    if
        List.any
            (\c ->
                c.subExerciseId == subExercise.id
                    && c.difficulty == difficultyToInt chosenDifficulty
            )
            completed
    then
        True

    else
        False
