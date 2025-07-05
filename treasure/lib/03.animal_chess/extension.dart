import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import 'base.dart';

class GridNotifier extends ValueNotifier<Grid> {
  GridNotifier(super.value);

  void clearAnimal() {
    value.animal = null;
    notifyListeners();
  }

  void revealAnimal() {
    value.animal?.isHidden = false;
    notifyListeners();
  }

  void toggleSelection(bool selected) {
    value.animal?.isSelected = selected;
    notifyListeners();
  }

  void toggleHighlight(bool highlighted) {
    value.isHighlighted = highlighted;
    notifyListeners();
  }

  void placeAnimal(Animal animal) {
    value.animal = animal;
    notifyListeners();
  }
}

// Animal类添加序列化方法
extension AnimalSerialization on Animal {
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'owner': owner.name,
    'isSelected': isSelected,
    'isHidden': isHidden,
  };

  // 可选：从JSON反序列化
  static Animal fromJson(Map<String, dynamic> json) => Animal(
    type: AnimalType.values.byName(json['type']),
    owner: GamerType.values.byName(json['owner']),
    isSelected: json['isSelected'] ?? false,
    isHidden: json['isHidden'] ?? true,
  );
}

// Grid类添加序列化方法
extension GridSerialization on Grid {
  Map<String, dynamic> toJson() => {
    'coordinate': coordinate,
    'type': type.name,
    'isHighlighted': isHighlighted,
    'animal': animal?.toJson(),
  };

  // 可选：从JSON反序列化
  static Grid fromJson(Map<String, dynamic> json) => Grid(
    coordinate: json['coordinate'],
    type: GridType.values.byName(json['type']),
    isHighlighted: json['isHighlighted'] ?? false,
    animal: json['animal'] != null
        ? AnimalSerialization.fromJson(json['animal'])
        : null,
  );
}

// GridNotifier添加序列化方法
extension GridNotifierSerialization on GridNotifier {
  Map<String, dynamic> toJson() => value.toJson();

  // 可选：从JSON反序列化
  GridNotifier fromJson(Map<String, dynamic> json) =>
      GridNotifier(GridSerialization.fromJson(json));
}
