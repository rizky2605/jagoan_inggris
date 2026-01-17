class ItemModel {
  final String id;
  final String name;
  final String category; // 'body', 'weapon', 'wings'
  final int price;
  final String assetPath; 

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.assetPath,
  });
}

// --- CATALOG TOKO RPG ---
final List<ItemModel> shopCatalog = [
  // --- BODY (AVATAR) ---
  ItemModel(id: 'default_avatar', name: 'Rookie', category: 'body', price: 0, assetPath: 'assets/models/avatar_default.glb'),
  ItemModel(id: 'wizard_robe', name: 'Mage Robe', category: 'body', price: 300, assetPath: 'assets/models/avatar_mage.glb'),
  ItemModel(id: 'knight_armor', name: 'Iron Armor', category: 'body', price: 800, assetPath: 'assets/models/avatar_knight.glb'),
  ItemModel(id: 'neon_warrior', name: 'Cyber Suit', category: 'body', price: 1500, assetPath: 'assets/models/avatar_neon.glb'),
  ItemModel(id: 'king_outfit', name: 'King Arthur', category: 'body', price: 5000, assetPath: 'assets/models/avatar_king.glb'),

  // --- WEAPON (BOWS) ---
  ItemModel(id: 'default_bow', name: 'Wooden Bow', category: 'weapon', price: 0, assetPath: 'assets/models/bow_wooden.glb'),
  ItemModel(id: 'ice_bow', name: 'Ice Bow', category: 'weapon', price: 400, assetPath: 'assets/models/bow_ice.glb'),
  ItemModel(id: 'fire_bow', name: 'Phoenix Bow', category: 'weapon', price: 1000, assetPath: 'assets/models/bow_fire.glb'),
  ItemModel(id: 'cyber_bow', name: 'Laser Bow', category: 'weapon', price: 2500, assetPath: 'assets/models/bow_cyber.glb'),
  ItemModel(id: 'god_bow', name: 'Artemis Bow', category: 'weapon', price: 9999, assetPath: 'assets/models/bow_god.glb'),

  // --- WINGS ---
  ItemModel(id: 'none', name: 'No Wings', category: 'wings', price: 0, assetPath: ''),
  ItemModel(id: 'fairy_wings', name: 'Fairy Wings', category: 'wings', price: 500, assetPath: 'assets/models/wings_fairy.glb'),
  ItemModel(id: 'demon_wings', name: 'Bat Wings', category: 'wings', price: 1200, assetPath: 'assets/models/wings_demon.glb'),
  ItemModel(id: 'angel_wings', name: 'Angel Wings', category: 'wings', price: 2000, assetPath: 'assets/models/wings_angel.glb'),
  ItemModel(id: 'mecha_wings', name: 'Jetpack', category: 'wings', price: 3500, assetPath: 'assets/models/wings_mecha.glb'),
];