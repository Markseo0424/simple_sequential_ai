import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'package:simple_sequential_ai/pysupport/make_model.dart';
import 'package:simple_sequential_ai/pysupport/make_train_loop.dart';
import 'package:simple_sequential_ai/pysupport/write_main_py.dart';

class TrainSetView extends StatefulWidget {
  ValueNotifier<bool> isTraining;

  TrainSetView({super.key, required this.trainLoopDS, required this.isTraining, required this.modelLayers});
  Map<String,dynamic> trainLoopDS;
  List<Map<String,dynamic>> modelLayers;

  @override
  State<TrainSetView> createState() => _TrainSetViewState();
}

class _TrainSetViewState extends State<TrainSetView> {
  get isTraining => widget.isTraining;

  List<bool> isSelected = [true,false];
  int optimizerIndex = 0;
  TextEditingController learningRateController = TextEditingController();
  TextEditingController epochController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if(widget.trainLoopDS['optimizer'] == 'Adam') {
      isSelected = [true,false];
      optimizerIndex = 0;
    }
    else {
      isSelected = [false,true];
      optimizerIndex = 1;
    }

    learningRateController.text = widget.trainLoopDS["lr"];
    epochController.text = widget.trainLoopDS['epoch'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text("optimizer : "),
                    ToggleButtons(
                      isSelected: isSelected,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        selectedBorderColor: Colors.black,
                        selectedColor: Colors.black,
                        fillColor: Colors.white,
                        color: Colors.white,
                        constraints: const BoxConstraints(
                          minHeight: 40.0,
                          minWidth: 80.0,
                        ),
                        onPressed: (index) {
                          optimizerIndex = index;
                          for(int i = 0; i < isSelected.length; i++){
                            isSelected[i] = i==index;
                          }
                          widget.trainLoopDS["optimizer"] = index == 0? "Adam" : "SGD";
                          setState(() {

                          });
                        },
                        children: const [
                          Text("Adam"),
                          Text("SGD")
                        ]
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("learning rate : "),
                    SizedBox(height: 30,width: 200, child:TextField(
                      controller: learningRateController,
                      onChanged: (str){
                        widget.trainLoopDS["lr"] = str;
                      },
                    )
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("epoch : "),
                    SizedBox(height: 30,width: 200, child:TextField(
                      controller: epochController,
                      keyboardType: TextInputType.number,
                      onChanged: (str) {
                        widget.trainLoopDS["epoch"] = str;
                      },
                    )
                    )
                  ],
                ),
                Spacer(flex: 1,),
                ElevatedButton(onPressed: () async {
                  if(isTraining.value == false) {
                    await Process.run(
                        "del", ["progress.json"], workingDirectory: "./pysupport",
                        runInShell: true);
                    await Process.run(
                        "del", ["epoch_loss.jpg"], workingDirectory: "./pysupport",
                        runInShell: true);
                    await WriteMainPy(
                        ModelBuilder(widget.modelLayers).moduleDefine("CNN"),
                        MakeTrainLoop({
                          "optimizer" : optimizerIndex == 0 ? "Adam" : "SGD",
                          "lr" : learningRateController.text,
                          "epoch" : epochController.text
                        }).trainLoopDefine()).saveMainPy();
                    var env = await getEnvironment("./pysupport");
                    print("train start! optimizer : ${optimizerIndex == 0
                        ? "Adam"
                        : "SGD"}, lr : ${learningRateController
                        .text}, epoch : ${epochController.text}");
                    isTraining.value = true;
                    await Process.run(
                        "python", ["main.py"], workingDirectory: "./pysupport",
                        environment: env,
                        runInShell: true);
                  }
                }, child:
                  Center(
                    child:
                    Text("Train start"),
                  )
                )
              ],
            ),
          ),
          const Center(
            child: Text("Train Set View"),
          ),
        ],
      ),
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
}