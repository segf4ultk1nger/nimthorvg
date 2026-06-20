import thorvg_capi
import engine, paint

type
  AccessorObj* = object of RootObj
    handle*: TvgAccessor

  Accessor* = ref AccessorObj

  AccessorCallback* = proc(paint: Paint): bool {.closure.}

var currentNimCallback {.threadvar.}: AccessorCallback

proc nativeAccessorCb(paintHandle: TvgPaint, data: pointer): bool {.cdecl.} =
  if currentNimCallback != nil and paintHandle != nil:
    # 【修改】因为 Paint 变成了 ref，这里必须通过构造过程创建，不能用 Paint(handle: ...)
    let p = newPaint(paintHandle) 
    return currentNimCallback(p)
  return false

proc isNil*(acc: Accessor): bool {.inline.} =
  acc == nil or acc.handle == nil

proc `=destroy`(acc: var AccessorObj) =
  if acc.handle != nil:
    discard tvgAccessorDel(acc.handle)
    acc.handle = nil

proc newAccessor*(): Accessor =
  let h = tvgAccessorNew()
  if h == nil:
    raise newException(ThorVGError, "Failed to create ThorVG Accessor object")
  result = Accessor(handle: h)

proc generateId*(name: string): uint32 {.inline.} =
  if name.len == 0:
    return 0
  result = tvgAccessorGenerateId(name.cstring).uint32

proc set*(
    acc: Accessor, root: Paint, callback: AccessorCallback
): Accessor {.discardable.} =
  if acc.isNil or root.handle == nil or callback == nil:
    return acc

  let oldCallback = currentNimCallback
  currentNimCallback = callback

  try:
    checkResult(
      tvgAccessorSet(
        acc.handle,
        root.handle,
        cast[proc(paint: TvgPaint, data: pointer): bool {.cdecl.}](nativeAccessorCb),
        nil,
      )
    )
  finally:
    currentNimCallback = oldCallback

  result = acc

proc iterate*(
    acc: Accessor, root: Paint, callback: AccessorCallback
): Accessor {.discardable, inline.} =
  acc.set(root, callback)

proc getName*(acc: Accessor, id: uint32): string =
  if acc.isNil:
    return ""
  let res = tvgAccessorGetName(acc.handle, id.uint32)
  if res != nil:
    result = $res
