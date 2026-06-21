import std/strutils
import thorvg_capi

type ThorVGError* = object of CatchableError

proc checkResult*(res: Tvg_Result) =
  if res == TVG_RESULT_SUCCESS:
    return

  let resStr = $res

  let msg =
    if resStr.startsWith("TVG_RESULT_"):
      resStr.replace("TVG_RESULT_", "").replace("_", " ").toLowerAscii().capitalizeAscii()
    else:
      "Unknown error: " & resStr

  raise newException(ThorVGError, msg)

proc getVersion*(): tuple[major, minor, micro: uint32, version: string] =
  var major, minor, micro: uint32
  var versionStr: cstring = nil

  checkResult(tvgEngineVersion(addr major, addr minor, addr micro, addr versionStr))

  let version =
    if versionStr != nil:
      $versionStr
    else:
      ""
  result = (major, minor, micro, version)

type ThorEngine* = object

var isEngineRunning: bool = false

proc termEngine*() =
  if isEngineRunning:
    discard tvg_engine_term()
    isEngineRunning = false

proc `=destroy`*(engine: ThorEngine) =
  termEngine()

proc `=copy`*(
  dest: var ThorEngine, src: ThorEngine
) {.error: "ThorEngine cannot be copied.".}

proc initThorEngine*(threads: Natural = 0): ThorEngine =
  if isEngineRunning:
    raise newException(ThorVGError, "ThorVG engine is already running.")

  checkResult(tvg_engine_init(threads.cuint))
  isEngineRunning = true
