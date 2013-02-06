Several old and new email clients have bugs. To block messages which trigger those
bugs, put in your `acl_check_mime`:

    # Bounday Space Gap
    drop   condition      = ${if match{$mime_boundary}{^( |\t)}{yes}{no}}
           message        = This message contains an broken MIME container (Boundary Space Gap). Boundary: $mime_boundary
           delay          = 45s
    # Blank MIME Folding Vulnerability
    drop   condition      = ${if match{$message_headers}{\N^\b$\N}{yes}{no}}
           message        = This message contains a broken headers (Blank Folding Vulnerability)
           delay          = 45s
    # CLSID hidden extension
    drop   condition      = ${if def:mime_filename {yes}{no}}
           condition      = ${if match{$mime_filename}{\N\{[a-hA-H0-9-]{25,}\}\N}{yes}{no}}
           message        = This message contains an unwanted CLSID hidden extension. Filename: $mime_filename
           delay          = 45s
    # Empty MIME Boundary Vulnerability
    drop   condition      = $mime_is_multipart
           condition      = ${if eqi{$mime_boundary}{}{yes}{no}}
           message        = This message contains a broken MIME container (Empty MIME Boundary)
           delay          = 45s
    # Too Many MIME Parts
    drop   condition      = ${if >{$mime_part_count}{256}{yes}{no}}
           message        = This message contains too many MIME parts: $mime_part_count (max 256)
           delay          = 45s
    # Long MIME Boundary Vulnerability
    drop   condition      = ${if >{${strlen:$mime_boundary}}{70}{yes}{no}}
           message        = This message contains a broken MIME container (Long MIME Boundary). Length: ${strlen:$mime_boundary}
           delay          = 45s
    # Line length too long
    drop   regex          = ^.{8191}
           message        = Line length in message or single header exceeds 8192.
           delay          = 45s
    # Filename length too long (> 512 characters)
    drop   condition      = ${if def:mime_filename {yes}{no}}
           condition      = ${if >{${strlen:$mime_filename}}{512}{yes}{no}}
           message        = Proposed filename too long: ${strlen:$mime_filename} characters (max 512 )
           delay          = 45s
    # Boundary length too long (> 1024)
    drop   condition      = ${if >{${strlen:$mime_boundary}}{1024}{yes}{no}}
           message        = Boundary length too long: ${strlen:$mime_boundary} characters (max 1024)
           delay          = 45s
