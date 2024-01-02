import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:process_run/process_run.dart';
import 'package:simple_sequential_ai/pysupport/write_app_py.dart';
import 'package:simple_sequential_ai/view/add_layer_view.dart';
import 'package:simple_sequential_ai/view/model_structure_view.dart';
import 'package:simple_sequential_ai/view/set_layer_view.dart';
import 'package:simple_sequential_ai/view/train_set_view.dart';
import 'package:simple_sequential_ai/view/train_status_view.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener{
  ValueNotifier<String> mode = ValueNotifier<String>("MODEL");
  ValueNotifier<int> layerCount = ValueNotifier<int>(0);
  ValueNotifier<int> selectedChangeDummy = ValueNotifier<int>(1);
  ValueNotifier<int> nameChangeDummy = ValueNotifier<int>(1);
  ValueNotifier<bool> isTraining = ValueNotifier<bool>(false);
  ValueNotifier<int> asyncCLK = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    initEnvironment();
    asyncCLK.addListener(updateCLK);
    asyncCLK.value = 1;
  }

  initEnvironment() async {
    await windowManager.setPreventClose(true);
    await createEnvironment("./pysupport", [
      "python.exe -m pip install --upgrade pip",
      "pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121",
      "pip install numpy",
      "pip install flask",
      "pip install matplotlib",
      "pip install opencv-python"
    ]);
    startPyServer();
  }

  startPyServer() async{
    await writeAppPy();
    var env = await getEnvironment("./pysupport");
    Process.run(
        "flask", ["run"], workingDirectory: "./pysupport",
        environment: env,
        runInShell: true);
  }

  @override
  dispose() async {
    asyncCLK.removeListener(updateCLK);
    await killPyServer();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () async{
                  Navigator.of(context).pop();
                  await killPyServer();
                  await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  killPyServer() async{
    File readFile = File("./pysupport/app.json");
    var data = await readFile.readAsString();
    var jsonData = jsonDecode(data);
    int PID = jsonData['PID'];

    await Process.run(
        "taskkill", ["/F","/PID","$PID"], workingDirectory: "./pysupport",
        runInShell: true);
  }

  updateCLK(){
    if(asyncCLK.value == 1){
      Future.delayed(const Duration(milliseconds: 500), () {
        asyncCLK.value = 0;
      });
    }
    else {
      Future.delayed(const Duration(milliseconds: 500), () {
        asyncCLK.value = 1;
      });
    }
  }

  Map<String,dynamic> trainLoopDS = {
    "optimizer" : "Adam",
    "lr" : "0.0001",
    "epoch" : "20",
  };
  Map<String,dynamic> modelDS = {
    "layers" : <Map<String,dynamic>>[],
    "selected" : null,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ValueListenableBuilder<String>(
          valueListenable: mode,
          builder: (BuildContext context, String value, Widget? child) {
            if(value == "MODEL"){
              return Row(
                children: [
                  Expanded(child: ModelStructureView(
                    mode: mode,
                    modelDS: modelDS,
                    layerCount: layerCount,
                    selectedChangeDummy: selectedChangeDummy, nameChangeDummy: nameChangeDummy,
                  )),
                  Expanded(child:
                  Column(
                    children: [
                      Expanded(child: SetLayerView(
                        modelDS: modelDS,
                        selectedChangeDummy: selectedChangeDummy, nameChangeDummy: nameChangeDummy,
                      )),
                      Expanded(child: AddLayerView(
                        modelDS: modelDS,
                        layerCount: layerCount,
                      )),
                    ],
                  ))
                ],
              );
            }
            else if(value == "TRAIN"){
              return Row(
                children: [
                  Expanded(child: TrainStatusView(
                    asyncCLK: asyncCLK,
                    mode: mode,
                    isTraining: isTraining,
                  )),
                  Expanded(child: TrainSetView(
                    trainLoopDS: trainLoopDS,
                    modelLayers: modelDS["layers"],
                    isTraining: isTraining,
                  )),
                ],
              );
            }
            else {
              return const Center(child: Text("null"),);
            }
          },
        )
    );
  }


  Future<Map<String, String>> getEnvironment(String pyDir) async {
    var isPromptDeclared = await Process.run("if", ["defined","PROMPT","echo","1"], workingDirectory: pyDir,
        runInShell: true);
    var promptResponse = await Process.run("echo", ["%PROMPT%"], workingDirectory: pyDir,
        runInShell: true);

    String prompt = isPromptDeclared.outText == "1"? promptResponse.outText : "\$P\$G";

    var isOldVirtualPromptDeclared = await Process.run("if", ["defined","_OLD_VIRTUAL_PROMPT","echo","1"], workingDirectory: pyDir,
        runInShell: true);
    if(isOldVirtualPromptDeclared.outText == "1") {
      var oldVirtualPromptResponse = await Process.run("echo", ["%_OLD_VIRTUAL_PROMPT%"],workingDirectory: pyDir,
          runInShell: true);
      prompt = oldVirtualPromptResponse.outText;
    }

    String oldVirtualPrompt = prompt;
    prompt = "(.venv) $prompt";
    String virtualEnvPrompt = "(.venv)";

    var isPythonHomeDeclared = await Process.run("if", ["defined","PYTHONHOME","echo","1"], workingDirectory: pyDir,
        runInShell: true);
    var pythonHomeResponse = await Process.run("echo", ["%PYTHONHOME%"], workingDirectory: pyDir,
        runInShell: true);
    var oldPythonHomeResponse = await Process.run("echo", ["%_OLD_VIRTUAL_PYTHONHOME%"], workingDirectory: pyDir,
        runInShell: true);

    String oldVirtualPythonHome = isPythonHomeDeclared.outText=="1"? pythonHomeResponse.outText : oldPythonHomeResponse.outText;
    String pythonHome = "";

    var envResponse = await Process.run("cd", [],workingDirectory: pyDir,
        runInShell: true);

    var isOldVirtualPathDeclared = await Process.run("if", ["defined","_OLD_VIRTUAL_PATH","echo","1"], workingDirectory: pyDir,
        runInShell: true);
    var oldVirtualPathResponse = await Process.run("echo", ["%_OLD_VIRTUAL_PATH%"],workingDirectory: pyDir,
        runInShell: true);
    var pathResponse = await Process.run("echo", ["%PATH%"],workingDirectory: pyDir,
        runInShell: true);

    String path = isOldVirtualPathDeclared.outText == "1"? oldVirtualPathResponse.outText : pathResponse.outText;
    String oldVirtualPath = isOldVirtualPathDeclared.outText == "1"? oldVirtualPathResponse.outText : pathResponse.outText;

    String virtualEnv = "${envResponse.outText}\\.venv";

    path = "$virtualEnv\\Scripts;$path";

    Map<String,String> env = {
      "VIRTUAL_ENV" : virtualEnv,
      "PROMPT" : prompt,
      "_OLD_VIRTUAL_PROMPT" : oldVirtualPrompt,
      "PYTHONHOME" : pythonHome,
      "_OLD_VIRTUAL_PYTHONHOME" : oldVirtualPythonHome,
      "PATH" : path,
      "_OLD_VIRTUAL_PATH" : oldVirtualPath,
      "VIRTUAL_ENV_PROMPT" : virtualEnvPrompt
    };

    return env;
  }
  Future<void> createEnvironment(String pyDir, List<String> installCommands) async {
    List<String> dir = pyDir.split('/');

    await Process.run("mkdir", [dir.last],
        runInShell: true);
    await Process.run("python", ["-m", "venv", ".venv"], workingDirectory: pyDir,
        runInShell: true);

    var env = await getEnvironment(pyDir);

    for(int i = 0; i < installCommands.length; i++) {
      print(installCommands[i]);
      List<String> commandSplit = installCommands[i].split(" ");
      String commandHead = commandSplit.removeAt(0);
      var response = await Process.run(
          commandHead, commandSplit, workingDirectory: pyDir,
          environment: env,
          runInShell: true);

      print(response.outText);
    }
  }
}