import std/[os, strutils, strformat, sequtils]

const
  ThorVGRepo = "https://github.com/thorvg/thorvg.git"
  ThorVGDir = "thorvg"
  IniFile = "release-opt.ini"
  TargetLibDir = "lib"

# --- 配置选项 ---
const ScalarConfig = [
  ("buildtype", "release"),
  ("loaders", "all"),       
  ("engines", "cpu"),       
  ("threads", "true"),       
  ("static", "true"),       
  ("tests", "false"),       
  ("simd", "true"),         
  ("bindings", "capi"),     
  ("file", "false")         
]

const CppArgs = [
  "-Os",
  "-ffunction-sections",
  "-fdata-sections",
  "-fno-asynchronous-unwind-tables",
  "-fno-strict-aliasing"
]

const CppLinkArgs = [
  "-Wl,--gc-sections",
  "-s"
]

proc generateIniFile() =
  var content = "[built-in options]\n"
  let cppArgsStr = CppArgs.mapIt("'" & it & "'").join(", ")
  content.add &"cpp_args = [{cppArgsStr}]\n"
  let cppLinkArgsStr = CppLinkArgs.mapIt("'" & it & "'").join(", ")
  content.add &"cpp_link_args = [{cppLinkArgsStr}]\n"
  
  for (key, val) in ScalarConfig:
    if val == "true" or val == "false":
      content.add &"{key} = {val}\n"
    else:
      content.add &"{key} = '{val}'\n"
  
  let targetPath = ThorVGDir / IniFile
  writeFile(targetPath, content)
  echo "✅ Generated ", targetPath

proc cloneIfNeeded() =
  if not dirExists(ThorVGDir):
    echo "📦 Cloning ThorVG..."
    exec &"git clone --depth 1 {ThorVGRepo} {ThorVGDir}"
    echo "✅ ThorVG cloned successfully"
  else:
    echo "📁 ThorVG directory already exists"

# --- 接收 buildDir 和是否为静态库的参数 ---
proc setupBuildDir(buildDir: string, isStatic: bool) =
  withDir ThorVGDir:
    let libTypeArg = if isStatic: "--default-library=static" else: "--default-library=shared"
    echo &"🔧 Running meson setup for {buildDir} ({libTypeArg})..."
    let cmd = &"meson setup {buildDir} {libTypeArg} --native-file {IniFile} --reconfigure"
    exec cmd
    echo "✅ Meson setup completed"

proc compile(buildDir: string) =
  withDir ThorVGDir / buildDir:
    echo &"🔨 Compiling ThorVG in {buildDir}..."
    exec "meson compile"
    echo "✅ Compilation completed"

proc collectArtifactsAndClean(buildDir: string) =
  echo &"\n🧹 Collecting artifacts from {buildDir}..."
  if not dirExists(TargetLibDir):
    mkDir(TargetLibDir)
  
  let srcBuildDir = ThorVGDir / buildDir / "src"
  # 涵盖静态库 (.a, .lib) 和动态库 (.dll, .dll.a, .so, .dylib 等)
  let targets = [
    "libthorvg-1.dll", "libthorvg-1.dll.a", 
    "libthorvg-1.a", "libthorvg-1.so", "libthorvg-1.dylib"
  ]
  var collectedCount = 0
  
  for target in targets:
    let sourcePath = srcBuildDir / target
    if fileExists(sourcePath):
      let destPath = TargetLibDir / target
      echo &"  🚚 Copying {target} -> {destPath}"
      cpFile(sourcePath, destPath)
      inc collectedCount
      
  if collectedCount == 0:
    echo &"  ⚠️  Warning: No matching library files found in {buildDir}!"
  else:
    echo &"  ✅ Successfully collected {collectedCount} artifact(s) to ./{TargetLibDir}/"

  # 如果你想自动删掉临时的 build 目录，可以取消注释下面几行
  let fullBuildDirPath = ThorVGDir / buildDir
  if dirExists(fullBuildDirPath):
    echo &"  🗑️  Removing temporary build directory: {fullBuildDirPath}"
    rmDir(fullBuildDirPath)

# --- 辅助函数：检测系统命令是否存在 ---
proc hasExe(exeName: string): bool =
  let checkCmd = if defined(windows): "cmd /c where " & exeName else: "which " & exeName
  try:
    exec checkCmd
    result = true
  except:
    result = false

# =============================================================================
# ✨ NimScript Tasks
# =============================================================================

task build_thorvg, "Run full ThorVG compilation pipeline (Static & Shared)":
  echo "=".repeat(50)
  echo "   ThorVG Build Script for Nim (Static & Shared)"
  echo "=".repeat(50)
  echo ""
  
  cloneIfNeeded()
  generateIniFile()

  # 定义两种构建配置：(目录名, 是否为静态库)
  let buildConfigs = [
    ("build_static", true),
    ("build_shared", false)
  ]

  for (bDir, isStatic) in buildConfigs:
    echo "\n" & "-".repeat(40)
    echo &"🚀 Starting build for: {bDir}"
    echo "-".repeat(40)
    setupBuildDir(bDir, isStatic)
    compile(bDir)
    collectArtifactsAndClean(bDir)
  
  # 所有编译完成后，可以选择清理 ini 文件
  let fullIniPath = ThorVGDir / IniFile
  if fileExists(fullIniPath):
    echo "\n🗑️  Removing temporary ini file..."
    rmFile(fullIniPath)

  echo "\n🎉 All ThorVG builds & cleanup completed!"

task c2nim, "Run c2nim translation":
  echo "🔍 Checking for c2nim dependency..."
  
  if not hasExe("c2nim"):
    echo "⚠️  c2nim not found. Trying to install it via nimble..."
    try:
      exec "nimble install c2nim -y --cpu:amd64"
      echo "✅ c2nim installed successfully via nimble!"
    except:
      echo "❌ Failed to install c2nim automatically. Please install it manually: 'nimble install c2nim'"
      quit(1)
  else:
    echo "   c2nim is already installed."

  let c2nimBin = if defined(windows): "c2nim.cmd" else: "c2nim"

  let headerPath = "thorvg/src/bindings/capi/thorvg_capi.h"
  let outputPath = "src/thorvg_capi.nim"
  let c2nimConfig = "tests/thorvg_capi.c2nim"

  if not fileExists(headerPath):
    echo &"❌ Error: ThorVG header file not found at '{headerPath}'!"
    quit(1)

  echo "🚀 Running c2nim processing..."
  if not dirExists("src"):
    mkDir("src")

  var cmd = ""
  if fileExists(c2nimConfig):
    cmd = &"{c2nimBin} --concat:all {c2nimConfig} {headerPath} -o:{outputPath}"
  else:
    cmd = &"{c2nimBin} {headerPath} -o:{outputPath}"

  echo "   Executing: ", cmd
  
  try:
    exec cmd
  except:
    echo "\n❌ OSError: Windows 无法直接唤起 'c2nim' 命令。"
    echo "   这通常是因为你的用户环境变量 PATH 还没有刷新。"
    echo "   [解决办法]: 请关闭当前的 PowerShell 窗口，重新打开一个，再运行 'nim c2nim' 即可！"
    quit(1)
  
  if fileExists(outputPath):
    echo &"✅ Successfully generated binding at: {outputPath}"
  else:
    echo &"❌ Error: Failed to generate {outputPath}"