module Games.TheoryApi exposing (Chord, MajorScaleAndKey, Mode, Note, TheoryDb, buildErrorMessage, fetchTheoryDb)

import Http
import Json.Decode as Decode


type alias Note =
    String


type alias TheoryDb =
    { majorScalesAndKeys : List MajorScaleAndKey
    , modes : List Mode
    , allNotes : List Note
    , chords : List Chord
    }


type alias Chord =
    { name : String
    , formula : List String
    }


type alias MajorScaleAndKey =
    { key : String
    , notes : List ( Int, Note )
    }


type alias Mode =
    { mode : String
    , formula : List String
    }


theoryDbDecoder : Decode.Decoder TheoryDb
theoryDbDecoder =
    Decode.map4 TheoryDb
        (Decode.field "major-scales" (Decode.list majorScaleAndKeyDecoder))
        (Decode.field "modes" (Decode.list modeDecoder))
        (Decode.field "all-notes" (Decode.list Decode.string))
        (Decode.field "chords" (Decode.list chordDecoder))


majorScaleAndKeyDecoder : Decode.Decoder MajorScaleAndKey
majorScaleAndKeyDecoder =
    Decode.map2 MajorScaleAndKey
        (Decode.field "key" Decode.string)
        (Decode.field "notes" (Decode.list Decode.string)
            |> Decode.map (List.indexedMap Tuple.pair)
        )


modeDecoder : Decode.Decoder Mode
modeDecoder =
    Decode.map2 Mode
        (Decode.field "mode" Decode.string)
        (Decode.field "formula" (Decode.list Decode.string))


chordDecoder : Decode.Decoder Chord
chordDecoder =
    Decode.map2 Chord
        (Decode.field "name" Decode.string)
        (Decode.field "formula" (Decode.list Decode.string))


fetchTheoryDb : (Result Http.Error TheoryDb -> msg) -> Cmd msg
fetchTheoryDb toMsg =
    Http.get
        { url = "http://localhost:5019/theory-db"
        , expect = Http.expectJson toMsg theoryDbDecoder
        }


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            "BadUrl: " ++ message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later"

        Http.NetworkError ->
            "Unable to reach server"

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ (statusCode |> String.fromInt)

        Http.BadBody message ->
            "BadBody: " ++ message


type alias Chord2 =
    { chord : String
    , root : String
    , formula : List Int
    , degrees : List String
    , notes : List String
    }


chord2Decoder : Decode.Decoder Chord2
chord2Decoder =
    Decode.map5 Chord2
        (Decode.field "chord" Decode.string)
        (Decode.field "root" Decode.string)
        (Decode.field "formula" (Decode.list Decode.int))
        (Decode.field "degrees" (Decode.list Decode.string))
        (Decode.field "notes" (Decode.list Decode.string))


fetchChord2 : String -> String -> (Result Http.Error Chord2 -> msg) -> Cmd msg
fetchChord2 root quality toMsg =
    Http.get
        { url =
            "https://music-theory-api-tuhh.onrender.com/api/v1/chords/"
                ++ root
                ++ "/"
                ++ quality
        , expect = Http.expectJson toMsg chord2Decoder
        }
