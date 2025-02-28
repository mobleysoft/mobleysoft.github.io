$emailFile = "emails.json"; 
if (!(Test-Path $emailFile)) { 
    New-Item -ItemType File -Path $emailFile | Set-Content -Value (ConvertTo-Json @()) 
}

$logFile = "system.log"; 
if (!(Test-Path $logFile)) { 
    New-Item -ItemType File -Path $logFile | Out-Null 
}

$attachmentsDir = "attachments"; 
if (!(Test-Path $attachmentsDir)) { 
    New-Item -ItemType Directory -Path $attachmentsDir | Out-Null 
}

$emails = Get-Content $emailFile | ConvertFrom-Json;

function logEvent($message) { 
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"; 
}

function parseAttachments($emailData, $outputDir) { 
    if ($emailData -match "Content-Disposition: attachment;") { 
        $attachmentBlocks = $emailData -split "Content-Disposition: attachment;"; 
        foreach ($block in $attachmentBlocks) { 
            if ($block -match "filename=\"(.+?)\"") { 
                $filename = $matches[1]; 
                $fileData = ($block -split "\r\n\r\n", 2)[1] -replace "\r\n", ""; 
                $filePath = Join-Path -Path $outputDir -ChildPath $filename; 
                [IO.File]::WriteAllBytes($filePath, [Convert]::FromBase64String($fileData)); 
                logEvent "Attachment saved: $filename"; 
            }
        }
    }
}

$listener = [System.Net.HttpListener]::new(); 
$listener.Prefixes.Add("http://*:1234/"); 
$listener.Start(); 
logEvent "HTTP Listener started.";

while ($listener.IsListening) { 
    $ctx = $listener.GetContext(); 
    $req = $ctx.Request; 
    $res = $ctx.Response; 

    if ($req.Url.AbsolutePath -eq "/") { 
        $res.ContentType = "text/html"; 
        $res.ContentLength64 = 0; 
        $res.OutputStream.Close(); 
    } elseif ($req.Url.AbsolutePath -eq "/emails") { 
        $res.ContentType = "application/json"; 
        $buf = [System.Text.Encoding]::UTF8.GetBytes(($emails | ConvertTo-Json -Depth 10)); 
        $res.ContentLength64 = $buf.Length; 
        $res.OutputStream.Write($buf, 0, $buf.Length); 
        $res.OutputStream.Close(); 
    } else { 
        $res.StatusCode = 404; 
        $res.ContentLength64 = 0; 
        $res.OutputStream.Close(); 
    } 
}

Start-Job { 
    $tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, 25); 
    $tcpListener.Start(); 

    while ($true) { 
        if ($tcpListener.Pending) { 
            $client = $tcpListener.AcceptTcpClient(); 
            $stream = $client.GetStream(); 
            $reader = New-Object System.IO.StreamReader($stream); 
            $writer = New-Object System.IO.StreamWriter($stream); 
            $writer.AutoFlush = $true; 
            $writer.WriteLine("220 mobleysoft.com ESMTP"); 
            $data = ""; 

            while ($true) { 
                $line = $reader.ReadLine(); 
                if ($line -eq "QUIT") { 
                    break; 
                } elseif ($line -eq "DATA") { 
                    $writer.WriteLine("354 End data with <CR><LF>.<CR><LF>"); 

                    while ($true) { 
                        $d = $reader.ReadLine(); 
                        if ($d -eq ".") { 
                            break; 
                        }
                        $data += $d + "`n"; 
                    }

                    $from = ($data -match "From: (.+)") ? $matches[1] : "Unknown"; 
                    $subject = ($data -match "Subject: (.+)") ? $matches[1] : "No Subject"; 
                    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); 
                    parseAttachments $data $attachmentsDir; 

                    $emails += @{ 
                        from = $from; 
                        subject = $subject; 
                        date = $date; 
                        attachments = (Test-Path $attachmentsDir) -and (Get-ChildItem -Path $attachmentsDir).Count 
                    }; 

                    $emails | ConvertTo-Json -Depth 10 | Set-Content -Path $emailFile; 
                    logEvent "Email received from $from with subject $subject."; 
                    $writer.WriteLine("250 OK"); 
                }
            }
            $client.Close(); 
        }
    }
}
