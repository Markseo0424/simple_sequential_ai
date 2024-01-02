class MakeTrainLoop {
  Map<String,String> parameters;
  MakeTrainLoop(this.parameters);

  String trainLoopDefine(){
    String res = '''
lr = ${parameters["lr"]}
optim = ${parameters["optimizer"] == "Adam"? "Adam" : "SGD"}(model.parameters(), lr=lr)
epoch_num = ${parameters["epoch"]}

epoch_loss = []

start = time.time()

with open("progress.json", "w") as f:
    try:
        for epoch in range(epoch_num):
            i = 0
            for data, label in train_loader:
                optim.zero_grad()

                preds = model(data.to(device))

                loss = nn.CrossEntropyLoss()(preds, label.to(device))
                loss.backward()
                optim.step()

                if time.time() - start > 0.5:
                    json_data = {
                        "epoch": epoch + 1,
                        "progress": f"{i}/{len(training_data) // 32}",
                        "loss": loss.item(),
                        "train_done": False
                    }

                    f.seek(0)
                    json.dump(json_data, f, indent=2)
                    f.truncate()

                    start = time.time()

                i += 1

            epoch_loss.append(loss.item())
            plt.plot(epoch_loss)
            plt.savefig("epoch_loss.jpg")
            print()
            print_str = ""

        json_data = {
            "epoch": epoch + 1,
            "progress": f"{i}/{len(training_data) // 32}",
            "loss": loss.item(),
            "train_done": True
        }

        f.seek(0)
        json.dump(json_data, f, indent=2)
        f.truncate()
    except:
        json_data = {
            "epoch": 0,
            "progress": "error",
            "loss": 0,
            "train_done": True
        }

        f.seek(0)
        json.dump(json_data, f, indent=2)
        f.truncate()

    f.close()
torch.save(model.state_dict(), "CIFAR.pth")
''';
    return res;
  }
}