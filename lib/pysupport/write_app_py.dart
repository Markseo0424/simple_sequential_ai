import 'dart:io';

Future<void> writeAppPy() async {
  String appPyStr = '''from flask import Flask, jsonify
import json
import base64
import cv2
import os

PID = os.getpid()

with open("app.json", "w") as f:
    json_data = {
        "PID": PID
    }
    json.dump(json_data, f, indent=2)
    f.close()

app = Flask(__name__)

@app.route('/progress', methods=['GET'])
def send_progress():
    img_path = "./epoch_loss.jpg"
    progress_path = "./progress.json"
    try:
        img = send_image(img_path)
    except:
        img = ""

    try:
        with open(progress_path, "r") as f:
            progress = json.load(f)
            f.close()
    except:
        progress = {}

    json_data = {
        "progress": progress,
        "graph_img": img
    }

    return jsonify(json_data)


def send_image(path):
    img = cv2.imread(path)

    jpg_img = cv2.imencode('.jpg', img)
    b64_string = base64.b64encode(jpg_img[1]).decode('utf-8')

    return b64_string

''';
  File writeFile = File("./pysupport/app.py");
  await writeFile.writeAsString(appPyStr);
}