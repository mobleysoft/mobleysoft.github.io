# server.ps1

# Import AuthMan functions
. "$PSScriptRoot..\Scripts\AuthMan.ps1"

# Initialize HttpListener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:8080/")
$listener.Start()
Write-Host "AuthMan AI Server is running on http://localhost:8080/"

try {
    while ($listener.IsListening) {
        # Asynchronously wait for incoming requests
        $context = $listener.GetContext()

        # Handle each request in a separate job to allow concurrent handling
        Start-Job -ScriptBlock {
            param ($ctx)

            $request = $ctx.Request
            $response = $ctx.Response

            try {
                # Route handling based on URL and HTTP method
                switch -Wildcard ($request.Url.AbsolutePath) {
                    "/" {
                        # Serve the signup/login page
                        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>AuthMan AI - Signup/Login</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
        form { margin-bottom: 20px; }
        label { display: block; margin-top: 10px; }
        input { width: 200px; padding: 5px; }
        button { margin-top: 10px; padding: 5px 10px; }
    </style>
</head>
<body>
    <h1>AuthMan AI</h1>

    <h2>Sign Up</h2>
    <form id="signup-form">
        <label for="signup-username">Username:</label>
        <input type="text" id="signup-username" name="username" required>

        <label for="signup-email">Email:</label>
        <input type="email" id="signup-email" name="email" required>

        <label for="signup-password">Password:</label>
        <input type="password" id="signup-password" name="password" required>

        <button type="submit">Sign Up</button>
    </form>

    <h2>Login</h2>
    <form id="login-form">
        <label for="login-username">Username or Email:</label>
        <input type="text" id="login-username" name="username" required>

        <label for="login-password">Password:</label>
        <input type="password" id="login-password" name="password" required>

        <button type="submit">Login</button>
    </form>

    <div id="message"></div>

    <script>
        document.getElementById('signup-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const username = document.getElementById('signup-username').value;
            const email = document.getElementById('signup-email').value;
            const password = document.getElementById('signup-password').value;

            const response = await fetch('/signup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, email, password })
            });

            const data = await response.json();
            document.getElementById('message').innerText = data.message || data.error;
        });

        document.getElementById('login-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const username = document.getElementById('login-username').value;
            const password = document.getElementById('login-password').value;

            const response = await fetch('/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });

            const data = await response.json();
            if (data.success) {
                // Store token in a cookie
                document.cookie = `authToken=${data.token}; path=/; HttpOnly`;
                window.location.href = '/hello';
            } else {
                document.getElementById('message').innerText = data.error;
            }
        });
    </script>
</body>
</html>
"@

                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $response.OutputStream.Close()
                    }

                    "/signup" {
                        if ($request.HttpMethod -eq "POST") {
                            $body = (New-Object IO.StreamReader($request.InputStream)).ReadToEnd()
                            $data = $body | ConvertFrom-Json

                            $result = Register-User -Username $data.username -Email $data.email -Password $data.password

                            if ($result.success) {
                                $response.StatusCode = 200
                                $response.ContentType = "application/json"
                                $responseString = @{ message = $result.message } | ConvertTo-Json
                            }
                            else {
                                $response.StatusCode = 400
                                $response.ContentType = "application/json"
                                $responseString = @{ error = $result.error } | ConvertTo-Json
                            }

                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            $response.OutputStream.Close()
                        }
                        else {
                            $response.StatusCode = 405
                            $response.OutputStream.Close()
                        }
                    }

                    "/login" {
                        if ($request.HttpMethod -eq "POST") {
                            $body = (New-Object IO.StreamReader($request.InputStream)).ReadToEnd()
                            $data = $body | ConvertFrom-Json

                            $result = Authenticate-User -Username $data.username -Password $data.password

                            if ($result.success) {
                                $response.StatusCode = 200
                                $response.ContentType = "application/json"
                                $responseString = @{ success = $true; token = $result.token; username = $result.username } | ConvertTo-Json
                            }
                            else {
                                $response.StatusCode = 400
                                $response.ContentType = "application/json"
                                $responseString = @{ success = $false; error = $result.error } | ConvertTo-Json
                            }

                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            $response.OutputStream.Close()
                        }
                        else {
                            $response.StatusCode = 405
                            $response.OutputStream.Close()
                        }
                    }

                    "/hello" {
                        # Serve the authenticated "Hello World" page
                        $authToken = ($request.Headers["Cookie"] -match "authToken=([^;]+)") ? $matches[1] : $null

                        if ($authToken) {
                            $validation = Validate-Session -Token $authToken
                            if ($validation.success) {
                                $username = $validation.username
                                $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hello, $username!</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
    </style>
</head>
<body>
    <h1>Hello, $username!</h1>
    <p>You are successfully logged in.</p>
    <a href="/">Logout</a>

    <script>
        // Logout by clearing the token and redirecting to home
        document.querySelector('a').addEventListener('click', function(e) {
            e.preventDefault();
            document.cookie = "authToken=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
            window.location.href = "/";
        });
    </script>
</body>
</html>
"@
                            }
                            else {
                                $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Unauthorized</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; color: red; }
    </style>
</head>
<body>
    <h1>Unauthorized</h1>
    <p>$($validation.error)</p>
    <a href="/">Go to Login</a>
</body>
</html>
"@
                            }
                        }
                        else {
                            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Unauthorized</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; color: red; }
    </style>
</head>
<body>
    <h1>Unauthorized</h1>
    <p>No authentication token found.</p>
    <a href="/">Go to Login</a>
</body>
</html>
"@
                        }

                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $response.OutputStream.Close()
                    }

                    default {
                        # 404 Not Found
                        $response.StatusCode = 404
                        $response.ContentType = "text/html"
                        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>404 Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; color: red; }
    </style>
</head>
<body>
    <h1>404 Not Found</h1>
    <p>The requested resource was not found on this server.</p>
    <a href="/">Go to Home</a>
</body>
</html>
"@
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $response.OutputStream.Close()
                    }
                }
            }
            catch {
                # Handle request processing errors
                $response.StatusCode = 500
                $response.ContentType = "text/plain"
                $errorMessage = "Internal Server Error"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
                Write-Error "Error processing request: $_"
            }
        } -ArgumentList $context | Out-Null
    }
}
catch {
    Write-Error "An error occurred in the server: $_"
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "AuthMan AI Server has stopped."
}
