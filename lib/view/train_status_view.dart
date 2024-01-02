import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';


class TrainStatusView extends StatefulWidget {
  ValueNotifier<String> mode;
  ValueNotifier<bool> isTraining;
  ValueNotifier<int> asyncCLK;

  TrainStatusView({super.key, required this.asyncCLK ,required this.mode, required this.isTraining});

  @override
  State<TrainStatusView> createState() => _TrainStatusViewState();
}

class _TrainStatusViewState extends State<TrainStatusView>{
  get clk => widget.asyncCLK;
  get mode => widget.mode;
  get isTraining => widget.isTraining;

  Image? graphImage;
  String? statusDescription;

  @override
  void initState() {
    super.initState();
    isTraining.addListener(_trainStartLoop);
    _trainStartLoop(forceStart: true);
  }

  @override
  void dispose(){
    isTraining.removeListener(_trainStartLoop);
    _trainEndLoop();
    super.dispose();
  }

  _trainStartLoop({bool forceStart = false}) {
    if(isTraining.value){
      clk.addListener(_getStatusLoop);
      _getStatusLoop();
    }
    else if(forceStart){
      _getStatusFromServer();
    }
  }

  _trainEndLoop() {
    if(isTraining.value) {
      clk.removeListener(_getStatusLoop);
    }
  }

  _getStatusLoop() async {
    if(isTraining.value && mode.value == "TRAIN"){
      _getStatusFromServer();
    }
  }

  Image _imageFromByte64(String byte64String){
    Uint8List byteImage = const Base64Decoder().convert(byte64String);

    return Image.memory(byteImage);
  }

  void _getStatusFromServer() async {
    var response = await get(Uri.parse('http://127.0.0.1:5000/progress'));
    try {
      var jsonData = jsonDecode(response.body);

      setState((){
        try {
          if(jsonData["graph_img"] == ""){
            throw Error();
          }
          graphImage = _imageFromByte64(jsonData['graph_img']);
        } catch (e){
          graphImage = null;
        }

        try {
          if(jsonData['progress'] == "{}"){
            throw Error();
          }
          statusDescription = jsonData['progress'].toString();
        } catch (e){
          statusDescription = null;
        }

        if(statusDescription != null) {
          try {
            if (jsonData['progress']['train_done'] == true) {
              isTraining.value = false;
            }
          }catch(e){}
        }
      });
    }catch(e){
      graphImage=null;
      statusDescription=null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink,
      child: Stack(
        children: [
          const Center(
            child: Text("Train Status View"),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 60,
              ),
              if(graphImage != null)
                Image(
                  image: graphImage!.image,
                  width: 500,
                  gaplessPlayback: true,
                ),
              const Spacer(flex: 1,),
              if(statusDescription != null)
                Center(
                  child: Text(
                    statusDescription!
                  ),
                ),
              SizedBox(height: 100,)
            ],
          ),
          Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding:const EdgeInsets.all(15),
            child: GestureDetector(
              onTap: (){
                mode.value = "MODEL";
              },
              child: Container(
                color: Colors.blue,
                height: 60,
                child: const Center(
                  child: Text(
                    "Model",
                  ),
                ),
              ),
            ),
          ),
        ),
      ]
      ),
    );
  }
}