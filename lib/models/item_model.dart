import 'package:flutter/material.dart';

// --- 1. DEFINISI ENUM (PENTING) ---
enum ItemCategory { body, head, wings, effect }
enum ItemRarity { common, rare, epic, legendary, mythic }

class ItemModel {
  final String id;
  final String name;
  final String description;
  final ItemCategory category; 
  final ItemRarity rarity;
  final int price;
  final String assetPath; 
  final String? linkedEffectId; 

  const ItemModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.rarity = ItemRarity.common,
    required this.price,
    required this.assetPath,
    this.linkedEffectId,
  });

  Color get rarityColor {
    switch (rarity) {
      case ItemRarity.common: return Colors.grey;
      case ItemRarity.rare: return Colors.blue;
      case ItemRarity.epic: return Colors.purple;
      case ItemRarity.legendary: return Colors.orange;
      case ItemRarity.mythic: return Colors.redAccent;
    }
  }
}

// --- 2. CATALOG TOKO (DATA SUDAH DIPERBAIKI) ---
// Perhatikan bagian category: ItemCategory.body (Bukan 'body')

final List<ItemModel> shopCatalog = [
  // ==========================================================
  // 1. BODY (AVATAR 3D)
  // ==========================================================
  ItemModel(
    id: 'default_avatar', 
    name: 'Rookie', 
    description: 'Pakaian standar pemula.',
    category: ItemCategory.body, // [FIX] Pakai Enum
    rarity: ItemRarity.common,
    price: 0, 
    assetPath: 'assets/models/avatar.glb'
  ),
  ItemModel(
    id: 'wizard_robe', 
    name: 'Mage Robe', 
    description: 'Jubah penyihir.',
    category: ItemCategory.body, // [FIX] Pakai Enum
    rarity: ItemRarity.rare,
    price: 300, 
    assetPath: 'assets/models/avatar_mage.glb'
  ),
  ItemModel(
    id: 'knight_armor', 
    name: 'Iron Armor', 
    description: 'Armor besi kuat.',
    category: ItemCategory.body, 
    rarity: ItemRarity.epic,
    price: 800, 
    assetPath: 'assets/models/avatar_knight.glb'
  ),
  ItemModel(
    id: 'monster_suit', 
    name: 'Monster Skin', 
    description: 'Menakutkan seperti monster.',
    category: ItemCategory.body, 
    rarity: ItemRarity.legendary,
    price: 1500, 
    assetPath: 'assets/models/monster.glb'
  ),
  ItemModel(
    id: 'teacher_suit', 
    name: 'Sensei', 
    description: 'Pakaian guru besar.',
    category: ItemCategory.body, 
    rarity: ItemRarity.legendary,
    price: 2000, 
    assetPath: 'assets/models/teacher.glb'
  ),

  // ==========================================================
  // 2. HEAD (HATS)
  // ==========================================================
  ItemModel(
    id: 'none_head', 
    name: 'No Hat', 
    category: ItemCategory.head, // [FIX] Pakai Enum
    price: 0, 
    assetPath: ''
  ),
  ItemModel(
    id: 'top_hat', 
    name: 'Gentleman', 
    category: ItemCategory.head, 
    rarity: ItemRarity.rare,
    price: 150, 
    assetPath: 'assets/models/hat.glb'
  ),

  // ==========================================================
  // 3. WINGS (SAYAP)
  // ==========================================================
  ItemModel(
    id: 'none_wings', 
    name: 'No Wings', 
    category: ItemCategory.wings, // [FIX] Pakai Enum
    price: 0, 
    assetPath: ''
  ),
  ItemModel(
    id: 'fairy_wings', 
    name: 'Fairy Wings', 
    category: ItemCategory.wings, 
    rarity: ItemRarity.epic,
    price: 500, 
    assetPath: 'assets/models/wings_fairy.glb'
  ),

  // ==========================================================
  // 4. EFFECTS (LOTTIE MAGIC)
  // ==========================================================
  ItemModel(
    id: 'fire', 
    name: 'Fireball', 
    description: 'Ledakan api panas.',
    category: ItemCategory.effect, // [FIX] Pakai Enum
    rarity: ItemRarity.common,
    price: 0, 
    assetPath: 'https://lottie.host/98205738-9999-4444-8888-123456789012/fireball.json'
  ),
  ItemModel(
    id: 'lightning', 
    name: 'Thunder', 
    description: 'Sambaran petir.',
    category: ItemCategory.effect, 
    rarity: ItemRarity.epic,
    price: 500, 
    assetPath: 'https://lottie.host/575a7062-d27c-473d-8067-d64f02636166/3Q9Z8Z3Z3Z.json'
  ),
];