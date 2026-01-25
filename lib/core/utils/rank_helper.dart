import 'package:flutter/material.dart';

class RankInfo {
  final String name;
  final Color color;
  final IconData icon;
  final int minMMR;
  final int maxMMR;

  RankInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.minMMR,
    required this.maxMMR,
  });
}

class RankHelper {
  static RankInfo getRank(int mmr) {
    if (mmr < 1000) {
      return RankInfo(name: 'BRONZE', color: const Color(0xFFCD7F32), icon: Icons.shield_outlined, minMMR: 0, maxMMR: 1000);
    } else if (mmr < 2000) {
      return RankInfo(name: 'SILVER', color: const Color(0xFFC0C0C0), icon: Icons.shield, minMMR: 1000, maxMMR: 2000);
    } else if (mmr < 3000) {
      return RankInfo(name: 'GOLD', color: const Color(0xFFFFD700), icon: Icons.workspace_premium, minMMR: 2000, maxMMR: 3000);
    } else if (mmr < 4000) {
      return RankInfo(name: 'PLATINUM', color: const Color(0xFF00E5FF), icon: Icons.diamond_outlined, minMMR: 3000, maxMMR: 4000);
    } else if (mmr < 5000) {
      return RankInfo(name: 'DIAMOND', color: const Color(0xFFB9F2FF), icon: Icons.diamond, minMMR: 4000, maxMMR: 5000);
    } else {
      return RankInfo(name: 'MYTHIC', color: const Color(0xFFFF0055), icon: Icons.local_fire_department, minMMR: 5000, maxMMR: 10000);
    }
  }
}