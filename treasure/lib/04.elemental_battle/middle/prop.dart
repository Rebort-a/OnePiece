import 'package:flutter/material.dart';

import '../../00.common/image/entity.dart';

import 'elemental.dart';
import 'dialog.dart';
import '../base/energy.dart';

class MapProp {
  final EntityType id;
  final String name;
  final String description;
  final String icon;
  final IconData? type;
  final int price;
  void Function(BuildContext context, Elemental elemental, VoidCallback after)
  handler;
  int count = 0;

  MapProp({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.price,
    required this.handler,
  });
}

class PropCollection {
  static final Map<EntityType, MapProp> totalItems = {
    EntityType.hospital: hospital,
    EntityType.sword: sword,
    EntityType.shield: shield,
    EntityType.scroll: scroll,
  };

  static MapProp emptyItem = MapProp(
    id: EntityType.road,
    name: '',
    description: '',
    icon: '',
    type: null,
    price: 0,
    handler: (context, elemental, after) {},
  );

  static MapProp hospital = MapProp(
    id: EntityType.hospital,
    name: '药',
    description: '生命值+32',
    icon: '💊',
    type: Icons.local_hospital,
    price: 10,
    handler: (context, elemental, after) {
      ElementalDialog.showSelectEnergyDialog(
        context: context,
        elemental: elemental,
        onSelected: (index) {
          after();
          elemental.recoverAppoint(index, Energy.healthStep);
        },
        available: false,
      );
    },
  );

  static MapProp sword = MapProp(
    id: EntityType.sword,
    name: '剑',
    description: '攻击力+8',
    icon: '🗡️',
    type: Icons.colorize,
    price: 10,
    handler: (context, elemental, after) {
      ElementalDialog.showSelectEnergyDialog(
        context: context,
        elemental: elemental,
        onSelected: (index) {
          after();
          elemental.upgradeAppointAttribute(index, AttributeType.atk);
        },
        available: false,
      );
    },
  );

  static MapProp shield = MapProp(
    id: EntityType.shield,
    name: '盾',
    description: '防御力+8',
    icon: '🛡️',
    type: Icons.shield,
    price: 10,
    handler: (context, elemental, after) {
      ElementalDialog.showSelectEnergyDialog(
        context: context,
        elemental: elemental,
        onSelected: (index) {
          after();
          elemental.upgradeAppointAttribute(index, AttributeType.def);
        },
        available: false,
      );
    },
  );
  static MapProp scroll = MapProp(
    id: EntityType.scroll,
    name: '回城卷轴',
    description: '随时随地可以回家',
    icon: '📜',
    type: null,
    price: 10,
    handler: (context, elemental, after) {},
  );
}
