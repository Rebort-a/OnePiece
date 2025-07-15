// 游戏进展类型
enum GameStep {
  disconnect,
  connected,
  frontConfig,
  rearWait,
  frontWait,
  rearConfig,
  action,
  gameOver,
}

extension TurnGameStepExtension on GameStep {
  String getExplaination() {
    switch (this) {
      case GameStep.disconnect:
        return "等待连接";
      case GameStep.connected:
        return "已连接，等待对手加入...";
      case GameStep.frontConfig:
        return "请配置";
      case GameStep.rearWait:
        return "等待先手配置";
      case GameStep.frontWait:
        return "等待后手配置";
      case GameStep.rearConfig:
        return "请配置或查看对方配置";
      case GameStep.action:
        return "进行中"; // 补充原代码中缺失的case
      case GameStep.gameOver:
        return "游戏结束";
    }
  }
}
