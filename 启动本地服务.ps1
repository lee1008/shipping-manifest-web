# 在本机启动静态网站，浏览器访问 http://localhost:5173
$port = 5173
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "发货清单在线版已启动：http://localhost:$port/" -ForegroundColor Green
Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Gray
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = $ctx.Request.Url.LocalPath.TrimStart('/')
  if (-not $path) { $path = 'index.html' }
  $file = Join-Path $root ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
  if (Test-Path $file -PathType Leaf) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $mime = @{
      '.html' = 'text/html; charset=utf-8'
      '.xlsx' = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      '.json' = 'application/json'
      '.js'   = 'application/javascript'
      '.css'  = 'text/css'
    }[$ext]
    if (-not $mime) { $mime = 'application/octet-stream' }
    $ctx.Response.ContentType = $mime
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
    $msg = [Text.Encoding]::UTF8.GetBytes('404 Not Found')
    $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
  }
  $ctx.Response.Close()
}
