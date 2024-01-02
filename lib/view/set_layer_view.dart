import 'dart:math';

import 'package:flutter/material.dart';

class SetLayerView extends StatelessWidget{
  Map<String,dynamic> modelDS;
  ValueNotifier<int> selectedChangeDummy;
  ValueNotifier<int> nameChangeDummy;

  SetLayerView({super.key, required this.modelDS, required this.selectedChangeDummy, required this.nameChangeDummy});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: selectedChangeDummy,
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0,horizontal: 30),
                child: Column(
                  children: [
                    if(getSelectedLayer() != null)
                      ...getParameterWidgets(getSelectedLayer()!),
                  ],
                ),
              );
            },
          ),
          const Center(
            child: Text("Set Layer View"),
          ),
        ],
      ),
    );
  }

  Map<String,dynamic>? getSelectedLayer() {
    if(modelDS["selected"] == null) return null;
    for(int i = 0; i < modelDS["layers"].length; i++) {
      if(modelDS["layers"][i]["layername"] == modelDS["selected"]) {
        return modelDS["layers"][i];
      }
    }
    return null;
  }

  Widget renderEntry(String key, String value, Function(String) onChanged){
    String parsedValue = value.substring(value.indexOf("|") + 1);
    TextEditingController controller = TextEditingController(text:parsedValue);
    return Container(
      color: Colors.white,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$key : "),
          SizedBox(height: 30,width: 100,
          child:TextField(
            onSubmitted: onChanged,
            onChanged: onChanged,
            onEditingComplete: (){
              onChanged(controller.text);
            },
            controller: controller,
          ),
          ),
        ],
      ),
    );
  }

  List<Widget> getParameterWidgets(Map<String,dynamic> layer) {
    List<Widget> res = [];

    for(int i = 0; i < layer.length; i++){
      var entry = layer.entries.elementAt(i);
      if(entry.value.contains("|")){
        res.add(renderEntry(entry.key, entry.value, (newVal) {
          if(entry.key == "layername") {
            newVal = nameCheck(modelDS["layers"], newVal);
          }
          String valueType = entry.value.substring(0, entry.value.indexOf("|"));
          //print("${entry.key}, $newVal");
          layer[entry.key] = "$valueType|$newVal";
          nameChangeDummy.value *= -1;
        }));
      }
    }

    return res;
  }


  String nameCheck(List<Map<String,dynamic>> layers, String currentName) {
    int counter = 0;
    int nameLen = currentName.length;

    for(int i = 0; i < layers.length; i++) {
      String layerName = layers[i]["layername"];
      layerName = layerName.substring(layerName.indexOf('|')+1);
      if(layerName == currentName) {
        counter = 1;
      }
    }

    if(counter == 0) {
      return currentName;
    } else {
      return "$currentName$counter";
    }
  }
}