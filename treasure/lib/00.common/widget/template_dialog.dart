import 'package:flutter/material.dart';

class TemplateDialog {
  static void confirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required bool Function() before,
    required VoidCallback onTap,
    required VoidCallback after,
  }) {
    if (before()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onTap();
                },
              ),
            ],
          );
        },
      ).then((value) {
        after();
      });
    }
  }

  static void inputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmButtonText,
    required Function(String input) onConfirm,
  }) {
    String input = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void optionDialog<T>({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmButtonText,
    required List<T> options,
    required Function(String input, T type) onConfirm,
  }) {
    String input = '';
    T selectedOption = options.first; // 默认选择第一个选项

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 通用下拉框
              DropdownButtonFormField<T>(
                value: selectedOption,
                onChanged: (T? newValue) {
                  if (newValue != null) {
                    selectedOption = newValue;
                  }
                },
                items: options.map((T option) {
                  return DropdownMenuItem<T>(
                    value: option,
                    child: Text(option.toString().split('.').last),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Select Option'),
              ),
              const SizedBox(height: 16),
              // 输入框
              TextField(
                onChanged: (value) {
                  input = value;
                },
                decoration: InputDecoration(hintText: hintText),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input, selectedOption);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void snackBarDialog(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
