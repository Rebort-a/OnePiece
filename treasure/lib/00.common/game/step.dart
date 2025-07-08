// 游戏进展类型
enum TurnGameStep {
  disconnect,
  connected,
  frontConfig,
  rearWait,
  frontWait,
  rearConfig,
  action,
  gamerOver,
}

// 为TurnGameStep添加扩展，实现getStatusMessage方法
extension TurnGameStepExtension on TurnGameStep {
  String getExplaination() {
    switch (this) {
      case TurnGameStep.disconnect:
        return "等待连接";
      case TurnGameStep.connected:
        return "已连接，等待对手加入...";
      case TurnGameStep.frontConfig:
        return "请配置";
      case TurnGameStep.rearWait:
        return "等待先手配置";
      case TurnGameStep.frontWait:
        return "等待后手配置";
      case TurnGameStep.rearConfig:
        return "请配置或查看对方配置";
      case TurnGameStep.action:
        return "进行中"; // 补充原代码中缺失的case
      case TurnGameStep.gamerOver:
        return "游戏结束";
    }
  }
}
