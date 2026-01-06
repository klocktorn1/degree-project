module Exercises.ChordGuesserExercise exposing (Model, Msg(..), init, subscriptions, update, view)

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
    , maybeRandomizedChordList : Maybe (List TheoryApi.Chord)
    , isGameStarted : Bool
    , chosenDifficulty : Difficulty
    , pendingFetches : Int
    , rootNotes : List String
    , maybeChosenChord : Maybe TheoryApi.Chord
    , correctChord : Maybe TheoryApi.Chord
    , correctChordNotes : Maybe (List String)
    , randomizedChordNotesBeforeShuffle : Maybe (List String)
    , lastRandomIndex : Maybe Int
    , areNotesShuffled : Bool
    , score : Int
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
    | CorrectChordPicked Int
    | DifficultyChosen Difficulty
    | ChordChosen TheoryApi.Chord
    | ChordGroupChosen Exercises.SubExercise
    | ChordNotesShuffled (List String)
    | ChordsShuffled (List TheoryApi.Chord)
    | ToggleNotesShuffle
    | BackToList
    | GoBack
    | ChordListUpdated (List TheoryApi.Chord)


type Difficulty
    = Easy
    | Medium
    | Hard
    | Advanced


init : () -> ( Model, Cmd Msg )
init _ =
    ( { maybeChords = Nothing
      , maybeRandomizedChordList = Nothing
      , maybeChosenChord = Nothing
      , isGameStarted = False
      , chosenDifficulty = Easy
      , pendingFetches = 0
      , rootNotes = [ "C", "G", "F" ]
      , correctChord = Nothing
      , correctChordNotes = Nothing
      , randomizedChordNotesBeforeShuffle = Nothing
      , lastRandomIndex = Nothing
      , areNotesShuffled = False
      , score = 0
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
                chordCount =
                    List.length chords

                cmd =
                    randomizeCorrectChord chordCount
            in
            ( { model | maybeChords = Just chords }, cmd )

        GotChordData (Err _) ->
            ( model, Cmd.none )

        GotCompletedSubExercises (Ok response) ->
            ( { model | completedSubExercises = Just response }, Cmd.none )

        GotCompletedSubExercises (Err err) ->
            ( { model | error = Just (Exercises.buildErrorMessage err) }, Cmd.none )

        DifficultyChosen difficulty ->
            let
                newDifficulty =
                    difficulty
            in
            ( { model | chosenDifficulty = newDifficulty, rootNotes = setRootNotes newDifficulty }, Cmd.none )

        ChordGroupChosen subExercise ->
            let
                fetchCount =
                    List.length model.rootNotes
            in
            ( { model
                | isGameStarted = True
                , pendingFetches = fetchCount
                , chosenSubExercise = Just subExercise
              }
            , TheoryApi.fetchChords model.rootNotes subExercise.endpoints GotChordData
            )

        ChordNotesShuffled chordNotes ->
            ( { model | correctChordNotes = Just chordNotes }, Cmd.none )

        ChordsShuffled chords ->
            ( { model | maybeRandomizedChordList = Just chords }, Cmd.none )

        CorrectChordPicked randomIndex ->
            let
                chordCount =
                    List.length (Maybe.withDefault [] model.maybeChords)

                newCorrectChord =
                    pickRandomChord model.maybeChords randomIndex

                notes =
                    newCorrectChord.notes

                updateChordListCmd =
                    Random.generate ChordListUpdated (updateChordList model.chosenDifficulty newCorrectChord (Maybe.withDefault [] model.maybeChords))

                _ =
                    Debug.log "chordCount" chordCount

                _ =
                    Debug.log "newCorrectChord" newCorrectChord

                _ =
                    Debug.log "notes" notes
            in
            case model.lastRandomIndex of
                Just lastIndex ->
                    if lastIndex == randomIndex && chordCount > 1 then
                        ( model, randomizeCorrectChord chordCount )

                    else
                        ( { model
                            | correctChord = Just newCorrectChord
                            , lastRandomIndex = Just randomIndex
                            , correctChordNotes = Just notes
                          }
                        , Cmd.batch [ shuffleNotesInChord model notes, updateChordListCmd ]
                        )

                Nothing ->
                    ( { model
                        | correctChord = Just newCorrectChord
                        , lastRandomIndex = Just randomIndex
                        , correctChordNotes = Just notes
                      }
                    , Cmd.batch [ shuffleNotesInChord model notes, updateChordListCmd ]
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

        BackToList ->
            ( model, Cmd.none )

        ChordListUpdated chords ->
            ( model, shuffleChords chords )


updateChordList : Difficulty -> TheoryApi.Chord -> List TheoryApi.Chord -> Random.Generator (List TheoryApi.Chord)
updateChordList difficulty correctChord chords =
    let
        pool =
            List.filter
                (\c ->
                    c /= correctChord
                )
                chords

        numberOfChords =
            case difficulty of
                Easy ->
                    4

                Medium ->
                    6

                Hard ->
                    8

                Advanced ->
                    10
    in
    RandomList.shuffle pool
        |> Random.map
            (\shuffled ->
                correctChord :: List.take numberOfChords shuffled
            )


listOfDifficulities : List Difficulty
listOfDifficulities =
    [ Easy, Medium, Hard, Advanced ]


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


view : Model -> Html Msg
view model =
    if model.isGameStarted then
        if model.hasUserWon then
            Html.section [HA.class "nes-container is-rounded"]
                [ Html.text "Good job! "
                , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text "< Back to exercises" ]
                ]

        else
            Html.section [HA.class "nes-container is-rounded"]
                [ viewCorrectChordNotes model
                , viewChords model
                , Html.p [ HA.class "score-bar" ]
                    [ Html.div
                        [ HA.class "score-bar-fill"
                        , HA.style "width" (String.fromInt (model.score * 10) ++ "%")
                        ]
                        []
                    ]
                , Html.button [ HA.class "custom-button", HE.onClick GoBack ] [ Html.text "< Back" ]
                ]

    else
        Html.section [HA.class "nes-container is-rounded"]
            [ Html.h1 [] [ Html.text "Chord Guesser" ]
            , viewDifficultyButtons listOfDifficulities
            , Html.div []
                [ Html.text ("Difficulty: " ++ difficultyToString model.chosenDifficulty)
                ]
            , Html.span [] [ Html.text "Toggle shuffle notes" ]
            , Html.label [ HA.class "switch", HA.for "shuffle-notes-switch" ]
                [ Html.input
                    [ HA.type_ "checkbox"
                    , HA.checked model.areNotesShuffled
                    , HA.id "shuffle-notes-switch"
                    , HE.onCheck (\checked -> ToggleNotesShuffle)
                    ]
                    []
                , Html.span [ HA.class "slider" ] []
                ]
            , viewSubExercises model
            , Html.button [ HA.class "custom-button", HE.onClick BackToList ] [ Html.text "< Back to exercises" ]
            ]


viewSubExercises : Model -> Html Msg
viewSubExercises model =
    case model.subExercises of
        Just subExercises ->
            Html.ul [ HA.class "card-grid" ] (List.map (viewSubExercise model.chosenDifficulty model.completedSubExercises) subExercises)

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

        isCompletedWithShuffle =
            case maybeCompleted of
                Just completed ->
                    checkIfCompletedWithShuffle chosenDifficulty completed.completedSubExercises subExercise

                Nothing ->
                    False
    in
    Html.li [ HA.class "card" ]
        [ Html.div [ HE.onClick (ChordGroupChosen subExercise), HA.class "card-data" ]
            [ Html.img [ HA.src "../assets/img/guitar3.png", HA.alt "guitar" ] []
            , Html.p [] [ Html.text subExercise.name ]
            , if isCompletedWithShuffle then
                Html.span [ HA.class "completed" ] [ Html.text " Completed *" ]

              else if isCompleted then
                Html.span [ HA.class "completed" ] [ Html.text " Completed" ]

              else
                Html.span [] []
            ]
        ]


viewDifficultyButtons : List Difficulty -> Html Msg
viewDifficultyButtons difficulties =
    Html.div []
        (List.map
            (\difficulty ->
                Html.button
                    [ HE.onClick (DifficultyChosen difficulty)
                    , HA.class "nes-btn"
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


viewChords : Model -> Html Msg
viewChords model =
    case model.maybeRandomizedChordList of
        Just chords ->
            Html.div [ HA.class "chords-container" ]
                (List.map viewChord chords)

        Nothing ->
            Html.div [] [ Html.text "No chords found" ]


viewChord : TheoryApi.Chord -> Html Msg
viewChord chord =
    Html.div [ HA.class "custom-button", HE.onClick (ChordChosen chord) ]
        [ Html.text chord.chord ]


viewCorrectChordNotes : Model -> Html Msg
viewCorrectChordNotes model =
    case model.correctChord of
        Just chord ->
            case model.correctChordNotes of
                Just correctChordNotes ->
                    if model.areNotesShuffled then
                        Html.p [ HA.class "chord-question" ]
                            [ Html.p [] [ Html.text "Which chord consists of these notes?" ]
                            , Html.br [] []
                            , Html.p [] [ Html.text (String.join " " correctChordNotes) ]
                            , Html.p [] [ Html.text ("The root note is " ++ (List.head chord.notes |> Maybe.withDefault "Something went wrong")) ]
                            ]

                    else
                        Html.p [ HA.class "chord-question" ]
                            [ Html.p [] [ Html.text "Which chord consists of these notes? " ]
                            , Html.br [] []
                            , Html.p [ HA.class "correct-notes"] [ Html.text (String.join " " correctChordNotes) ]
                            ]

                Nothing ->
                    Html.p [] [ Html.text "No chord foundddd" ]

        Nothing ->
            Html.p [] [ Html.text "No chord found" ]


shuffleNotesInChord : Model -> List String -> Cmd Msg
shuffleNotesInChord model notes =
    if model.areNotesShuffled then
        Random.generate ChordNotesShuffled (RandomList.shuffle notes)

    else
        Cmd.none


shuffleChords : List TheoryApi.Chord -> Cmd Msg
shuffleChords chords =
    Random.generate ChordsShuffled (RandomList.shuffle chords)


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


randomizeCorrectChord : Int -> Cmd Msg
randomizeCorrectChord maxIndex =
    if maxIndex <= 0 then
        Cmd.none

    else
        Random.generate CorrectChordPicked (Random.int 0 (maxIndex - 1))


boolToInt : Bool -> Int
boolToInt bool =
    if bool then
        1

    else
        0


checkIfChordIsCorrect : Model -> ( Model, Cmd Msg )
checkIfChordIsCorrect model =
    case ( model.maybeChosenChord, model.correctChord ) of
        ( Just chosenChord, Just correctChord ) ->
            if chosenChord.chord == correctChord.chord then
                let
                    newScore =
                        model.score + 1

                    chordCount =
                        List.length (Maybe.withDefault [] model.maybeChords)

                    updatedModel =
                        if newScore == 10 then
                            let
                                cmd =
                                    case model.chosenSubExercise of
                                        Just chosenSubExercise ->
                                            let
                                                body =
                                                    Encode.object
                                                        [ ( "sub_exercise_id", Encode.int chosenSubExercise.id )
                                                        , ( "difficulty", Encode.int (difficultyToInt model.chosenDifficulty) )
                                                        , ( "shuffled", Encode.int (boolToInt model.areNotesShuffled) )
                                                        ]
                                            in
                                            Exercises.createCompletedExerciseEntry body CompletedExerciseEntryResponse

                                        Nothing ->
                                            Cmd.none
                            in
                            ( { model | hasUserWon = True }, cmd )

                        else
                            ( { model | score = newScore }, randomizeCorrectChord chordCount )
                in
                updatedModel

            else
                let
                    newScore =
                        if model.score == 0 then
                            0

                        else
                            model.score - 1
                in
                ( { model | score = newScore }, Cmd.none )

        _ ->
            ( model, Cmd.none )


checkIfCompleted : Difficulty -> List Exercises.CompletedSubExercise -> Exercises.SubExercise -> Bool
checkIfCompleted chosenDifficulty completed subExercise =
    if
        List.any
            (\c ->
                c.subExerciseId
                    == subExercise.id
                    && c.difficulty
                    == difficultyToInt chosenDifficulty
            )
            completed
    then
        True

    else
        False


checkIfCompletedWithShuffle : Difficulty -> List Exercises.CompletedSubExercise -> Exercises.SubExercise -> Bool
checkIfCompletedWithShuffle chosenDifficulty completed subExercise =
    if
        List.any
            (\c ->
                c.subExerciseId
                    == subExercise.id
                    && c.difficulty
                    == difficultyToInt chosenDifficulty
                    && c.shuffled
                    == 1
            )
            completed
    then
        True

    else
        False
