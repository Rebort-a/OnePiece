import 'package:flutter/material.dart';

// 定义数独格子状态枚举
enum CellType {
  fixed, // 固定数字，不可更改
  locked, // 已锁定，解锁后可以更改
  editable, // 可更改，可以填入多个数字
}

// 数独格子数据模型
class SudokuCell {
  final int row;
  final int col;
  CellType type;
  int fixedDigit;
  final List<int> spareDigits = [];

  SudokuCell({
    required this.row,
    required this.col,
    required this.type,
    this.fixedDigit = 0,
  });
}

// 单元格状态管理类（统一管理所有类型的单元格）
class CellNotifier extends ValueNotifier<SudokuCell> {
  CellNotifier(super.value);

  void addDigit(int digit) {
    if (value.type == CellType.editable) {
      if (!value.spareDigits.contains(digit)) {
        value.spareDigits.add(digit);
        value.spareDigits.sort(); // 排序
        notifyListeners();
      }
    }
  }

  void removeDigit(int digit) {
    if (value.type == CellType.editable) {
      if (value.spareDigits.contains(digit)) {
        value.spareDigits.remove(digit);
        notifyListeners();
      }
    }
  }

  void clearDigits() {
    if (value.type == CellType.editable) {
      value.spareDigits.clear();
      notifyListeners();
    }
  }

  void lock() {
    if (value.type == CellType.editable && value.spareDigits.length == 1) {
      value.fixedDigit = value.spareDigits.first;
      value.type = CellType.locked;
      notifyListeners();
    }
  }

  void unlock() {
    if (value.type == CellType.locked) {
      value.fixedDigit = 0;
      value.type = CellType.editable;
      notifyListeners();
    }
  }
}
