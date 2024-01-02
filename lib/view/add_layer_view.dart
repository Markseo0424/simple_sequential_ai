import 'dart:math';

import 'package:flutter/material.dart';

class AddLayerView extends StatelessWidget{
  ValueNotifier<int> layerCount;

  Map<String,dynamic> modelDS;

  List<Map<String,dynamic>> layerDS = [
    {
      "classname" : "nn.Conv2d",
      "layername" : "STRING|conv2d",
      "in_channels" : "INT|0",
      "out_channels" : "INT|0",
      "bias" : "BOOL|True",
      "kernel_size" : "INT|3",
      "padding" : "INT|1",
      "stride" : "INT|1",
    },
    {
      "classname" : "nn.Linear",
      "layername" : "STRING|linear",
      "in_features" : "INT|0",
      "out_features" : "INT|0",
      "bias" : "BOOL|True",
    },
    {
      "classname" : "nn.MaxPool2d",
      "layername" : "STRING|maxpool2d",
      "kernel_size" : "INT|2",
      "stride" : "INT|2",
    },
    {
      "classname" : "nn.ReLU",
      "layername" : "STRING|relu",
    },
    {
      "classname" : "nn.Flatten",
      "layername" : "STRING|flatten",
    }
  ];

  AddLayerView({super.key, required this.modelDS, required this.layerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange,
      child: Stack(
        children: [
          const Center(
            child: Text("Add Layer View"),
          ),
          Padding(
            padding: EdgeInsets.all(60),
            child: ListView(
              children: [
                ...layerDS.map((element) {
                  return GestureDetector(
                      onTap: (){
                        String newName = nameCheck(modelDS["layers"], element["layername"]);
                        Map<String,dynamic> newElement = Map.from(element);
                        newElement["layername"] = newName;

                        modelDS["layers"].add(newElement);
                        layerCount.value += 1;
                      },
                      child: Container(height: 30, color: Colors.white, child: Center(child: Text(element["classname"]))));
                })
              ],
            ),
          ),
        ],
      ),
    );
  }

  String nameCheck(List<Map<String,dynamic>> layers, String currentName) {
    int counter = 1;
    int nameLen = currentName.length;

    for(int i = 0; i < layers.length; i++) {
      String layerName = layers[i]["layername"];
      if(layerName.substring(0,min(layerName.length, nameLen)) == currentName) {
        int? parsed = int.tryParse(layerName.substring(nameLen));
        if(parsed != null) {
          counter = counter <= parsed? parsed + 1 : counter;
        }
      }
    }
    return "$currentName$counter";
  }
}