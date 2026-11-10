# Draws the "printer + check" icon and writes PrinterCheck.ico (16-256 px, PNG-compressed).
param([string]$Out = (Join-Path $PSScriptRoot 'PrinterCheck.ico'), [string]$Preview)
Add-Type -AssemblyName System.Drawing

function New-Frame([int]$S) {
    $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.Clear([System.Drawing.Color]::Transparent)
    $u = $S / 256.0
    function Rc($x,$y,$w,$h) { New-Object System.Drawing.RectangleF ([single]($x*$u)), ([single]($y*$u)), ([single]($w*$u)), ([single]($h*$u)) }
    function Round($rect, $r) {
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = [single]($r*2*$u)
        $p.AddArc($rect.X,$rect.Y,$d,$d,180,90); $p.AddArc($rect.Right-$d,$rect.Y,$d,$d,270,90)
        $p.AddArc($rect.Right-$d,$rect.Bottom-$d,$d,$d,0,90); $p.AddArc($rect.X,$rect.Bottom-$d,$d,$d,90,90)
        $p.CloseFigure(); $p
    }
    $navy  = [System.Drawing.Color]::FromArgb(255,30,58,95)
    $body  = [System.Drawing.Color]::FromArgb(255,71,85,105)
    $paper = [System.Drawing.Color]::FromArgb(255,248,250,252)
    $line  = [System.Drawing.Color]::FromArgb(255,148,163,184)

    # paper out the back
    $g.FillPath((New-Object System.Drawing.SolidBrush $paper), (Round (Rc 68 22 120 90) 6))
    $g.DrawPath((New-Object System.Drawing.Pen $navy, ([single](5*$u))), (Round (Rc 68 22 120 90) 6))
    # printer body
    $g.FillPath((New-Object System.Drawing.SolidBrush $body), (Round (Rc 22 100 212 98) 18))
    $g.DrawPath((New-Object System.Drawing.Pen $navy, ([single](6*$u))), (Round (Rc 22 100 212 98) 18))
    # front tray + paper
    $g.FillPath((New-Object System.Drawing.SolidBrush $paper), (Round (Rc 62 160 132 74) 6))
    $g.DrawPath((New-Object System.Drawing.Pen $navy, ([single](5*$u))), (Round (Rc 62 160 132 74) 6))
    $lp = New-Object System.Drawing.Pen $line, ([single](5*$u))
    $g.DrawLine($lp, [single](80*$u), [single](184*$u), [single](176*$u), [single](184*$u))
    $g.DrawLine($lp, [single](80*$u), [single](204*$u), [single](150*$u), [single](204*$u))
    # status light
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,56,189,248))), (Rc 188 118 18 18))

    # green check badge (bottom-right)
    $badge = Rc 140 120 112 112
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), (Rc 134 114 124 124))
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,34,197,94))), $badge)
    $cp = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ([single](14*$u))
    $cp.StartCap='Round'; $cp.EndCap='Round'; $cp.LineJoin='Round'
    $g.DrawLines($cp, @(
        (New-Object System.Drawing.PointF ([single](164*$u)), ([single](178*$u))),
        (New-Object System.Drawing.PointF ([single](185*$u)), ([single](200*$u))),
        (New-Object System.Drawing.PointF ([single](228*$u)), ([single](152*$u)))))
    $g.Dispose(); $bmp
}

$sizes = 16,24,32,48,64,128,256
$pngs = foreach ($s in $sizes) {
    $b = New-Frame $s; $ms = New-Object IO.MemoryStream
    $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    if ($Preview -and $s -eq 256) { $b.Save($Preview, [System.Drawing.Imaging.ImageFormat]::Png) }
    ,$ms.ToArray()
}
$fs = [IO.File]::Create($Out); $w = New-Object IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$sizes.Count)
$offset = 6 + 16*$sizes.Count
for ($i=0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]; $dim = if ($s -ge 256) { 0 } else { $s }
    $w.Write([byte]$dim); $w.Write([byte]$dim); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]$pngs[$i].Length); $w.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $w.Write($p) }
$w.Close(); $fs.Close()
"Wrote $Out"
