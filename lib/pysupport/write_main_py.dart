import 'dart:io';

class WriteMainPy {
  String modelDefineString;
  String trainLoopDefineString;

  WriteMainPy(this.modelDefineString,this.trainLoopDefineString);

  Future<void> saveMainPy() async {
    File writeFile = File("./pysupport/main.py");
    await writeFile.writeAsString(getFullPyCode());
  }

  String getFullPyCode(){
    return '''import json

import matplotlib.pyplot as plt
import torchvision.transforms as T

from torchvision.datasets.cifar import CIFAR10
from torchvision.transforms import Compose
from torchvision.transforms import RandomHorizontalFlip, RandomCrop, Normalize

import torch
import torch.nn as nn
from torch.utils.data.dataloader import DataLoader
from torch.optim.adam import Adam
from torch.optim.sgd import SGD

import time

device = "cuda" if torch.cuda.is_available() else "cpu"

# transform 전처리
transforms = Compose([
    # T.ToPILImage(),
    RandomCrop((32, 32), padding=4),
    RandomHorizontalFlip(p=0.5),
    T.ToTensor(),

    Normalize(mean=(0.4914, 0.4822, 0.4465), std=(0.247, 0.243, 0.261)),
    # T.ToPILImage()
])

# CIFAR-10 dataset 불러오기
training_data = CIFAR10(
    root="./",
    train=True,
    download=True,
    transform=transforms
)

test_data = CIFAR10(
    root="./",
    train=False,
    download=True,
    transform=transforms
)

# dataloader 만들기
train_loader = DataLoader(training_data, batch_size=32, shuffle=True)
test_loader = DataLoader(test_data, batch_size=32, shuffle=False)

$modelDefineString

$trainLoopDefineString
''';
  }
}