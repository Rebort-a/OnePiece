import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import '../middleware/elemental.dart';

class CastPage extends StatefulWidget {
  final int totalPoints;

  const CastPage({super.key, required this.totalPoints});

  @override
  State<CastPage> createState() => _CastPageState();
}

class _CastPageState extends State<CastPage> {
  final EnergyConfigs _configs = EnergyConfigs.defaultConfigs(skillPoints: 1);
  late int _remainingPoints;
  EnergyType _currentEnergy = EnergyType.water;
  final PageController _pageController = PageController(
    initialPage: 2,
    viewportFraction: 0.6,
  );

  @override
  void initState() {
    super.initState();
    _remainingPoints = widget.totalPoints;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[_currentEnergy];
    final isEnabled = config.aptitude;

    return Scaffold(
      appBar: AppBar(
        title: const Text('角色配置'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _completeCast),
        ],
      ),
      body: Column(
        children: [
          _buildPointRegion(),
          _buildEnergyRegion(),
          _buildAttributeRegion(config, isEnabled),
          _buildSkillTreeRegion(config, isEnabled),
        ],
      ),
    );
  }

  Widget _buildPointRegion() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      '剩余点数: $_remainingPoints',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildEnergyRegion() => Container(
    height: 120,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: PageView.custom(
      controller: _pageController,
      onPageChanged: (index) =>
          setState(() => _currentEnergy = EnergyType.values[index]),
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) => _buildTransformedCard(index),
        childCount: EnergyType.values.length,
      ),
    ),
  );

  Widget _buildTransformedCard(int index) {
    const double scaleFactor = 0.8; // 缩放因子
    Matrix4 matrix = Matrix4.identity();

    // 计算变换效果
    if (index == _currentEnergy.index) {
      // 当前页
      double currScale = 1 - (_currentEnergy.index - index) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else if (index == _currentEnergy.index + 1) {
      // 下一页
      double currScale =
          scaleFactor + (_currentEnergy.index - index + 1) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else if (index == _currentEnergy.index - 1) {
      // 上一页
      double currScale = 1 - (_currentEnergy.index - index) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else {
      // 其他页
      matrix = Matrix4.diagonal3Values(1.0, scaleFactor, 1.0)
        ..setTranslationRaw(0.0, 120.0 * (1 - scaleFactor) / 2, 0.0);
    }

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentEnergy = EnergyType.values[index]);
      },
      child: Transform(
        transform: matrix,
        child: _buildEnergyCard(
          EnergyType.values[index],
          _configs[EnergyType.values[index]].aptitude,
        ),
      ),
    );
  }

  Widget _buildEnergyCard(EnergyType type, bool isEnabled) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isEnabled ? null : Colors.grey.withValues(alpha: 0.3),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  energyNames[type.index],
                  style: TextStyle(
                    fontSize: 32,
                    color: isEnabled ? null : Colors.grey,
                  ),
                ),
                Text(
                  type.toString().split('.').last,
                  style: TextStyle(
                    fontSize: 16,
                    color: isEnabled ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleEnergy(type),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.check : Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRegion(EnergyConfig config, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttributeControl(
            AttributeType.hp,
            config.healthPoints,
            isEnabled,
          ),
          _buildAttributeControl(
            AttributeType.atk,
            config.attackPoints,
            isEnabled,
          ),
          _buildAttributeControl(
            AttributeType.def,
            config.defencePoints,
            isEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeControl(
    AttributeType type,
    int points,
    bool isEnabled,
  ) {
    final step = switch (type) {
      AttributeType.hp => Energy.healthStep,
      AttributeType.atk => Energy.attackStep,
      AttributeType.def => Energy.defenceStep,
    };
    final baseValue = Energy.baseAttributes[_currentEnergy.index][type.index];
    final value = baseValue + points * step;

    return Column(
      children: [
        Text(
          attributeNames[type.index],
          style: TextStyle(color: isEnabled ? null : Colors.grey),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: isEnabled ? null : Colors.grey),
              onPressed: isEnabled && points > 0
                  ? () => _updateAttribute(type, -1)
                  : null,
            ),
            Text(
              points.toString(),
              style: TextStyle(color: isEnabled ? null : Colors.grey),
            ),
            IconButton(
              icon: Icon(Icons.add, color: isEnabled ? null : Colors.grey),
              onPressed: isEnabled && _remainingPoints > 0
                  ? () => _updateAttribute(type, 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillTreeRegion(EnergyConfig config, bool isEnabled) {
    final skills = SkillCollection.totalSkills[_currentEnergy.index];
    final learnedCount = config.skillPoints;

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: skills.length,
        itemBuilder: (_, index) =>
            _buildSkillCard(skills[index], index, learnedCount, isEnabled),
      ),
    );
  }

  Widget _buildSkillCard(
    CombatSkill skill,
    int index,
    int learnedCount,
    bool isEnabled,
  ) {
    final isLearned = index < learnedCount;
    final canLearn = isEnabled && index == learnedCount;
    final canForget =
        isEnabled && isLearned && index == learnedCount - 1 && index > 0;

    return GestureDetector(
      onTap: () => _showSkillDialog(skill, index, canLearn, canForget),
      child: Container(
        decoration: BoxDecoration(
          color: isLearned
              ? Colors.blue.withValues(alpha: isEnabled ? 1.0 : 0.5)
              : Colors.grey[300]!.withValues(alpha: isEnabled ? 1.0 : 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              skill.name,
              style: TextStyle(
                color: isLearned ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              skill.type == SkillType.active ? '主动' : '被动',
              style: TextStyle(color: isLearned ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEnergy(EnergyType type) {
    setState(() {
      final config = _configs[type];
      final wasEnabled = config.aptitude;

      int enabledCount = _configs.values
          .where((config) => config.aptitude)
          .length;

      if (wasEnabled && enabledCount <= 1) {
        return;
      }

      if (wasEnabled) {
        config.aptitude = false;
        // 返还点数
        _remainingPoints +=
            config.healthPoints +
            config.attackPoints +
            config.defencePoints +
            (config.skillPoints - 1) +
            3;

        // 重置配置
        config.healthPoints = 0;
        config.attackPoints = 0;
        config.defencePoints = 0;
        config.skillPoints = 1;
      } else if (_remainingPoints >= 3) {
        _remainingPoints -= 3;
        config.aptitude = true;
      }
    });
  }

  void _updateAttribute(AttributeType type, int delta) {
    setState(() {
      final config = _configs[_currentEnergy];
      final current = switch (type) {
        AttributeType.hp => config.healthPoints,
        AttributeType.atk => config.attackPoints,
        AttributeType.def => config.defencePoints,
      };

      if (delta > 0 && _remainingPoints > 0) {
        switch (type) {
          case AttributeType.hp:
            config.healthPoints++;
            break;
          case AttributeType.atk:
            config.attackPoints++;
            break;
          case AttributeType.def:
            config.defencePoints++;
            break;
        }
        _remainingPoints--;
      } else if (delta < 0 && current > 0) {
        switch (type) {
          case AttributeType.hp:
            config.healthPoints--;
            break;
          case AttributeType.atk:
            config.attackPoints--;
            break;
          case AttributeType.def:
            config.defencePoints--;
            break;
        }
        _remainingPoints++;
      }
    });
  }

  void _showSkillDialog(
    CombatSkill skill,
    int index,
    bool canLearn,
    bool canForget,
  ) {
    final config = _configs[_currentEnergy];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标: ${CombatSkill.getTargetText(skill.targetType)}'),
            Text('效果: ${skill.description}'),
          ],
        ),
        actions: [
          if (canLearn)
            TextButton(
              onPressed: _remainingPoints > 0
                  ? () {
                      setState(() {
                        config.skillPoints++;
                        _remainingPoints--;
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    }
                  : null,
              child: const Text('学习'),
            ),
          if (canForget)
            TextButton(
              onPressed: () {
                setState(() {
                  config.skillPoints--;
                  _remainingPoints++;
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              },
              child: const Text('遗忘'),
            ),
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _completeCast() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_configs);
    }
  }
}
