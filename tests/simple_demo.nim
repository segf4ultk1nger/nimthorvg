import std/strformat

import src/engine
import src/canvas
import src/scene
import src/shape

const
  DemoWidth = 128
  DemoHeight = 128

when isMainModule:
  discard initThorEngine()

  var buffer = newSeq[uint32](DemoWidth * DemoHeight)

  let swCanvas = newSwCanvas()
  swCanvas.viewport(0, 0, DemoWidth.int32, DemoHeight.int32)
  swCanvas.setTarget(buffer, DemoWidth.uint32, DemoWidth.uint32, DemoHeight.uint32)

  var rootScene = newScene()
  var rect = newRect(24, 24, 80, 80)
  rect.fill(0'u8, 180'u8, 255'u8, 255'u8)
  rect.stroke(255'u8, 255'u8, 255'u8, 4.0)
  rootScene.add(rect)
  let sceneAdded = swCanvas.push(rootScene)
  echo &"sceneAdded={sceneAdded}"
  swCanvas.render(clear = true)

  let centerIndex = (DemoHeight div 2) * DemoWidth + (DemoWidth div 2)
  let cornerIndex = 0

  var nonZeroPixels = 0
  for pixel in buffer:
    if pixel != 0:
      inc nonZeroPixels

  echo &"ThorVG initialized: true"
  echo &"nonZeroPixels={nonZeroPixels}, corner={buffer[cornerIndex]}, center={buffer[centerIndex]}"

  if nonZeroPixels > 0 and buffer[centerIndex] != 0 and buffer[cornerIndex] == 0:
    echo "ThorVG binding demo: PASS"
  else:
    echo "ThorVG binding demo: FAIL"

  termEngine()