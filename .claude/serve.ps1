# Minimal static file server for the game (no external runtimes needed)
$port = 8321
$root = Split-Path -Parent $PSScriptRoot   # project root (parent of .claude)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Output "Serving $root on http://localhost:$port/"
$mime = @{
  '.html'='text/html; charset=utf-8'; '.js'='text/javascript'; '.css'='text/css'
  '.png'='image/png'; '.jpg'='image/jpeg'; '.gif'='image/gif'; '.svg'='image/svg+xml'
  '.json'='application/json'; '.ico'='image/x-icon'
}
while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $reqPath = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  if ($reqPath -eq '/') { $reqPath = '/index.html' }
  $file = Join-Path $root ($reqPath -replace '/', '\')
  $full = [System.IO.Path]::GetFullPath($file)
  if ($full.StartsWith($root) -and (Test-Path $full -PathType Leaf)) {
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $ext = [System.IO.Path]::GetExtension($full).ToLower()
    $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
    $msg = [System.Text.Encoding]::UTF8.GetBytes('404')
    $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
  }
  $ctx.Response.Close()
}
