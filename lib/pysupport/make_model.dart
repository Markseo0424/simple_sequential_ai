class ModelBuilder {
  List<String> classNames = [];
  List<List<String>> parameters = [];
  List<String> layerNames = [];

  ModelBuilder(List<Map<String,dynamic>> moduleDS) {
    for(int i = 0; i < moduleDS.length; i++){
      for(int j = 0; j < moduleDS[i].length; j++){
        var entry = moduleDS[i].entries.elementAt(j);
        if(entry.key == "classname") {
          classNames.add(entry.value);
          parameters.add([]);
        }
        else if(entry.key == "layername") {
          layerNames.add(entry.value.substring(entry.value.indexOf("|") + 1));
        }
        else {
          parameters.last.add("${entry.key}=${entry.value.substring(entry.value.indexOf("|") + 1)}");
        }
      }
    }
  }

  String moduleDefine(String classname) {
    String initString = "";
    String forwardString = "";

    for(int i = 0; i < classNames.length; i++){
      initString = "$initString        self.${layerNames[i]} = ${classNames[i]}(${parameters[i].join(",")})\n";
      forwardString = "$forwardString        x = self.${layerNames[i]}(x)\n";
    }

    String modelDefinition = '''class $classname(nn.Module):
    def __init__(self):
        super($classname, self).__init__()
$initString

    def forward(self, x):
$forwardString
        return x
        

model = $classname()
model.to(device)
''';

    return modelDefinition;
  }
}