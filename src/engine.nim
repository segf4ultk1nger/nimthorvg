import std/strutils
import thorvg_capi

type ThorVGError* = object of CatchableError
  ## Custom exception type raised when a ThorVG operation fails.

proc checkResult*(res: Tvg_Result) =
  ## Internal helper to check the result of a ThorVG C API call.
  ## If the result is not `TVG_RESULT_SUCCESS`, it translates the result
  ## into a readable error message and raises a `ThorVGError`.
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
  ## Retrieves the version of the ThorVG engine runtime.
  ## 
  ## Returns a tuple containing the major, minor, and micro version numbers, 
  ## along with a formatted string version (e.g., "0.15.0").
  ##
  ## Throws a `ThorVGError` if retrieving the version fails internally.
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
  ## A RAII-based wrapper responsible for managing the initialization and
  ## termination of the ThorVG engine runtime.
  ##
  ## The ThorVG engine requires an active runtime environment for rendering operations.
  ## It sets up an internal task scheduler and handles resource management.
  ##
  ## This type cannot be copied to prevent premature engine termination.

var isEngineRunning: bool = false

proc termEngine*() =
  ## Terminates the ThorVG engine runtime manually.
  ## 
  ## Cleans up allocated resources and stops any internal threads initialized by the engine.
  ## This function is safe to call multiple times, but will only perform the actual
  ## termination if the engine is currently running.
  if isEngineRunning:
    discard tvg_engine_term()
    isEngineRunning = false

proc `=destroy`*(engine: ThorEngine) =
  ## Automatically terminates the ThorVG engine when the `ThorEngine` object
  ## goes out of scope, ensuring proper cleanup of resources and worker threads.
  termEngine()

proc `=copy`*(
  dest: var ThorEngine, src: ThorEngine
) {.error: "ThorEngine cannot be copied.".}
  ## Disables copying of `ThorEngine` to prevent multiple objects from 
  ## managing the same global engine runtime lifetime.

proc initThorEngine*(threads: Natural = 0): ThorEngine =
  ## Initializes the ThorVG engine runtime.
  ##
  ## Sets up the internal task scheduler and launches the specified number of worker
  ## threads to enable parallel rendering.
  ##
  ## **Parameters:**
  ## - `threads`: The number of worker threads to launch. A value of `0` indicates 
  ##   that only the main thread will be used.
  ##
  ## **Returns:**
  ## - A `ThorEngine` instance that automatically manages the engine's lifetime.
  ##
  ## **Raises:**
  ## - `ThorVGError` if the engine is already running or if the initialization fails.
  ##
  ## **Note:**
  ## The underlying ThorVG engine uses internal reference counting for initialization.
  ## However, the number of threads is fixed during the first successful initialization
  ## and cannot be changed subsequently.
  if isEngineRunning:
    raise newException(ThorVGError, "ThorVG engine is already running.")

  checkResult(tvg_engine_init(threads.cuint))
  isEngineRunning = true
