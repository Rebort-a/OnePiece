enum GamerType { front, rear }

extension GamerTypeeExtension on GamerType {
  GamerType get opponent =>
      this == GamerType.front ? GamerType.rear : GamerType.front;
}
