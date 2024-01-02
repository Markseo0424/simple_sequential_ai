import 'package:flutter/material.dart';
import 'package:simple_sequential_ai/pysupport/make_model.dart';

class ModelStructureView extends StatefulWidget {
  ValueNotifier<String> mode;
  ValueNotifier<int> layerCount;
  ValueNotifier<int> selectedChangeDummy;
  ValueNotifier<int> nameChangeDummy;

  Map<String, dynamic> modelDS;

  ModelStructureView(
      {super.key, required this.mode, required this.layerCount, required this.modelDS, required this.selectedChangeDummy, required this.nameChangeDummy});

  @override
  State<ModelStructureView> createState() => _ModelStructureViewState();
}

class _ModelStructureViewState extends State<ModelStructureView>{
  get modelDS => widget.modelDS;
  get mode => widget.mode;
  get layerCount => widget.layerCount;
  get selectedChangeDummy => widget.selectedChangeDummy;
  get nameChangeDummy => widget.nameChangeDummy;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Stack(
        children: [
          const Center(
            child: Text("Model Structure View"),
          ),
          GestureDetector(
              onTap:(){
                setState(() {
                  modelDS["selected"] = null;
                  selectedChangeDummy.value *= -1;
                });
              },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 100, 100),
            child: ValueListenableBuilder(valueListenable: layerCount,
              builder: (context, value, child){
                return ValueListenableBuilder(
                  valueListenable: nameChangeDummy,
                  builder: (context, value, child) {
                    return ListView(
                      children: [
                        ...modelDS["layers"].map((element) {
                          String layerName = element["layername"];
                          return GestureDetector(
                            onTap: (){
                              setState(() {
                                modelDS["selected"] = layerName;
                                selectedChangeDummy.value *= -1;
                              });
                            },
                            child: Container(
                              height : 60,
                              color: layerName == modelDS["selected"]? Colors.grey : Colors.white,
                              child: Center(
                                child: Text(layerName.substring(layerName.indexOf("|") + 1)),
                              ),
                            ),
                          );
                        }
                        ),
                      ],
                    );
                  }
                );
              },
            ),
          ),
          Positioned(
              top: 0,
              bottom: 0,
              right: 15,
              child: Center(
                child: GestureDetector(
                  onTap:() {
                    if(modelDS["selected"] != null) {
                      for(int i = 0; i < modelDS["layers"].length; i++){
                        if(modelDS["layers"][i]["layername"] == modelDS["selected"]) {
                          modelDS["layers"].removeAt(i);
                          modelDS["selected"] = null;
                          selectedChangeDummy.value *= -1;
                          layerCount.value -= 1;
                        }
                      }
                    }
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    color: Colors.white,
                    child: Center(
                      child: Text("X"),
                    ),
                  ),
                ),
              )
          ),
          Positioned(
            bottom:0,
            left: 0,
            right: 0,
            child: Padding(
              padding:const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: (){
                  mode.value = "TRAIN";
                },
                child: Container(
                  color: Colors.blue,
                  height: 60,
                  child: const Center(
                    child: Text(
                      "Train",
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}