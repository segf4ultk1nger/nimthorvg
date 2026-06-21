## ThorVG Nim Wrapper Example
## 
## This example demonstrates the usage of the ThorVG Nim wrapper
import std/math
import stb_image/write as stbwrite

import ../src/nimthorvg

proc saveBufferToPng*(buffer: seq[uint32], width, height: int, filename: string) =
  # ThorVG 默认是 ARGB8888 格式，我们需要将其转换为 stb_image_write 预期的 RGBA8888 字节数组
  var rgbaBytes = newSeq[uint8](width * height * 4)
  
  for i in 0 ..< (width * height):
    let pixel = buffer[i]
    
    # 从 ARGB 提取颜色通道 (假设是大端序/标准内存布局，根据渲染结果如果不红蓝颠倒就OK)
    # 如果后续图片颜色红蓝反了，可以调换下面 A、R * 8 的位移位置
    let a = uint8((pixel shr 24) and 0xFF)
    let r = uint8((pixel shr 16) and 0xFF)
    let g = uint8((pixel shr 8) and 0xFF)
    let b = uint8(pixel and 0xFF)
    
    # 写入 RGBA 格式
    rgbaBytes[i * 4 + 0] = r
    rgbaBytes[i * 4 + 1] = g
    rgbaBytes[i * 4 + 2] = b
    rgbaBytes[i * 4 + 3] = a

  # 调用 stb_image_write 的写入函数
  # 参数：文件名，宽，高，通道数(4代表RGBA)，数据指针
  let success = writePNG(
    filename = filename,
    w = width,
    h = height,
    comp = 4,
    data = rgbaBytes,
    stride_in_bytes = width * 4
  )
  
  if not success:
    echo "保存图片失败！"
  else:
    echo "图片已成功保存至：", filename

var myBuffer = newSeq[uint32](800 * 600)

proc main() =
  try:
    # Get version info
    let version = getVersion()
    echo "ThorVG Version: ", version.version
    echo "Major: ", version.major, ", Minor: ", version.minor, ", Micro: ", version.micro
    
    # Create a software canvas
    let canvas = newSwCanvas()
    canvas.setTarget(myBuffer, 800u32, 800u32, 600u32, ColorspaceARGB8888)
    
    # Create shapes using fluent API
    let rect = newRect(50, 50, 200, 150, rx = 10)
        .fill(rgba(255, 100, 100, 255))
        .stroke(rgba(0, 0, 0, 255), width = 3.0)
    
    let circle = newCircle(vec2(400, 200), 80)
        .fill(rgba(100, 255, 100, 200))
        .stroke(rgba(0, 0, 255, 255), width = 2.0)
    
    # Create a complex shape using path builder
    let star = newShape()
    var path = star.path()
    
    # Draw a 5-pointed star
    let centerX = 600.0
    let centerY = 400.0
    let outerRadius = 60.0
    let innerRadius = 25.0
    
    for i in 0..9:
      let angle = float(i) * PI / 5.0
      let radius = if i mod 2 == 0: outerRadius else: innerRadius
      let x = centerX + radius * cos(angle)
      let y = centerY + radius * sin(angle)
        
      if i == 0:
        path.moveTo(x, y)
      else:
        path.lineTo(x, y)
    
    path.close()
    star.fill(rgba(255, 255, 0, 255)).stroke(rgba(255, 0, 0, 255), width = 2.0)
    
    # Apply transformations
    circle.rotate(45.0)
    star.scale(1.2)
    star.translate(50, -50)
    
    # Add shapes to canvas
    canvas.push(rect)
    canvas.push(circle)
    canvas.push(star)
    
    # Render the scene
    canvas.render()
    
    # Get the buffer (for saving to file or displaying)
    echo "Rendered ", myBuffer.len, " pixels"

    saveBufferToPng(myBuffer, 800, 600, "output.png")
  except CatchableError as e:
    echo "出错了！错误信息是: ", e.msg

when isMainModule:
  # Initialize the engine
  discard initThorEngine(threads = 4)
  main() 
  termEngine()