import 'package:flutter/material.dart';

enum ItemCategory { body, head, wings, effect }
enum ItemRarity { common, rare, epic, legendary, mythic }

class ItemModel {
  final String id;
  final String name;
  final String description;
  final ItemCategory category; 
  final ItemRarity rarity;
  final int price;
  final String assetPath; // GLB (untuk 3D) atau JSON (untuk Effect)

  const ItemModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.rarity = ItemRarity.common,
    required this.price,
    required this.assetPath,
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

final List<ItemModel> shopCatalog = [
  // --- BODY ---
  const ItemModel(
    id: 'avatar1', 
    name: 'Michelle', 
    category: ItemCategory.body, 
    price: 0, 
    assetPath: 'assets/models/avatar1_none_none.glb' 
  ),
  const ItemModel(
    id: 'avatar2', 
    name: 'Nayla', 
    category: ItemCategory.body, 
    rarity: ItemRarity.rare,
    price: 500, 
    assetPath: 'assets/models/avatar2_none_none.glb' 
  ),

  // --- HEAD ---
  const ItemModel(
    id: 'none', // ID 'none' tidak butuh aset
    name: 'Lepas Topi', 
    category: ItemCategory.head, 
    price: 0, 
    assetPath: '' 
  ),
  const ItemModel(
    id: 'hat1', 
    name: 'Witch Hat', 
    category: ItemCategory.head, 
    rarity: ItemRarity.epic,
    price: 200, 
    assetPath: 'assets/models/hat1.glb'
  ),

  // --- WINGS ---
  const ItemModel(
    id: 'none', 
    name: 'Lepas Sayap', 
    category: ItemCategory.wings, 
    price: 0, 
    assetPath: ''
  ),
  const ItemModel(
    id: 'wings1', 
    name: 'Phoenix', 
    category: ItemCategory.wings, 
    rarity: ItemRarity.legendary,
    price: 1000, 
    assetPath: 'assets/models/wings1.glb'
  ),

  // --- EFFECT ---
  const ItemModel(
    id: 'fire', 
    name: 'Fireball', 
    category: ItemCategory.effect, 
    price: 0, 
    assetPath: 'assets/effects/fire.json' // Path JSON Lottie
  ),
  const ItemModel(
    id: 'lightning', 
    name: 'Thunder', 
    category: ItemCategory.effect, 
    rarity: ItemRarity.epic,
    price: 500, 
    assetPath: 'assets/effects/lightning.json'
  ),
];