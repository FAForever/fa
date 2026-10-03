param(
    [Parameter(Mandatory = $true)]
    [string]$SourceReplay,

    [Parameter(Mandatory = $true)]
    [string]$OutputReplay
)

$bytes = [IO.File]::ReadAllBytes($SourceReplay)
$headerLength = [Array]::IndexOf($bytes, [byte]10)

if ($headerLength -lt 1) {
    throw 'Invalid FAF replay: JSON header was not found.'
}

$header = [Text.Encoding]::UTF8.GetString($bytes, 0, $headerLength)
$metadata = ConvertFrom-Json $header
$payloadOffset = $headerLength + 1

if ($metadata.compression -eq 'zstd') {
    $python = Get-Command python -ErrorAction Stop
    $pythonCode = @'
import sys
import zstandard

source, output, offset = sys.argv[1], sys.argv[2], int(sys.argv[3])
with open(source, 'rb') as input_file, open(output, 'wb') as output_file:
    input_file.seek(offset)
    zstandard.ZstdDecompressor().copy_stream(input_file, output_file)
'@

    & $python.Source -c $pythonCode $SourceReplay $OutputReplay $payloadOffset
    if ($LASTEXITCODE -ne 0) {
        throw 'Zstandard replay decompression failed.'
    }
}
elseif ($null -eq $metadata.compression) {
    $payload = [Text.Encoding]::ASCII.GetString($bytes, $payloadOffset, $bytes.Length - $payloadOffset).Trim()
    $compressed = [Convert]::FromBase64String($payload)
    $input = [IO.MemoryStream]::new($compressed, 6, $compressed.Length - 10)
    $deflate = [IO.Compression.DeflateStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
    $output = [IO.File]::Create($OutputReplay)

    try {
        $deflate.CopyTo($output)
    }
    finally {
        $output.Dispose()
        $deflate.Dispose()
        $input.Dispose()
    }
}
else {
    throw "Unsupported FAF replay compression: $($metadata.compression)"
}

if (-not (Test-Path -LiteralPath $OutputReplay) -or (Get-Item -LiteralPath $OutputReplay).Length -eq 0) {
    throw 'Replay conversion produced no data.'
}
