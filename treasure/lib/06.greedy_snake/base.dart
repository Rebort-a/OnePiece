import 'dart:math';
import 'dart:ui';

const double mapWidth = 2000;
const double mapHeight = 2000;
const double snakeHeadSize = 12;
const double snakeBodySize = 18;
const double iniSnakeSpeed = 100;
const double fastSnakeSpeed = 180;
const double foodSize = 20;
const double snakeGrowthPerFood = 20;

class Snake {
  List<Offset> body = [];
  double currentSpeed = iniSnakeSpeed;

  Offset head;
  double length;
  double angle;

  Snake({required this.head, required this.length, required this.angle}) {
    body.add(head);
  }

  // 计算相对视野偏移
  Offset calculateViewOffset(Size viewSize) {
    double offsetX = head.dx - viewSize.width / 2;
    double offsetY = head.dy - viewSize.height / 2;

    return Offset(offsetX, offsetY);
  }

  // 更新蛇的位置
  void updatePosition(double deltaTime) {
    // 计算移动距离
    double moveDistance = currentSpeed * deltaTime;

    // 更新蛇头位置
    double dx = cos(angle) * moveDistance;
    double dy = sin(angle) * moveDistance;
    head = Offset(head.dx + dx, head.dy + dy);

    // 更新蛇身
    body.insert(0, head);
    while (body.length > 1 && _calculateSnakeLength() > length) {
      body.removeLast();
    }
  }

  void updateAngle(double newAngle) {
    angle = newAngle;
  }

  void updateSpeed(bool isFaster) {
    currentSpeed = isFaster ? fastSnakeSpeed : iniSnakeSpeed;
  }

  void updateLength(int step) {
    length += step;
  }

  // 计算蛇的总长度
  double _calculateSnakeLength() {
    if (body.length < 2) return 0;
    double length = 0;
    for (int i = 0; i < body.length - 1; i++) {
      length += (body[i] - body[i + 1]).distance;
    }
    return length;
  }
}

class Food {
  Offset position;
  Food({required this.position});
}
