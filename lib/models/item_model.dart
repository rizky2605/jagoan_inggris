class ItemModel {
  final String id;
  final String name;
  final String category; // 'body', 'weapon', 'wings'
  final int price;
  final String assetPath; // Lokasi file 3D (.glb)

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.assetPath,
  });
}

// --- DATA KATALOG TOKO ---
final List<ItemModel> shopCatalog = [
  // CATEGORY: BODY (Avatar Skin)
  ItemModel(id: 'default_avatar', name: 'Rookie', category: 'body', price: 0, assetPath: 'assets/models/avatar_default.glb'),
  ItemModel(id: 'neon_warrior', name: 'Neon Warrior', category: 'body', price: 500, assetPath: 'assets/models/avatar_neon.glb'), // Pastikan punya filenya nanti
  
  // CATEGORY: WEAPON
  ItemModel(id: 'default_bow', name: 'Wooden Bow', category: 'weapon', price: 0, assetPath: 'assets/models/bow_basic.glb'),
  ItemModel(id: 'cyber_bow', name: 'Cyber Bow', category: 'weapon', price: 1200, assetPath: 'assets/models/bow_cyber.glb'),

  // CATEGORY: WINGS
  ItemModel(id: 'none', name: 'No Wings', category: 'wings', price: 0, assetPath: ''),
  ItemModel(id: 'angel_wings', name: 'Angel Wings', category: 'wings', price: 2000, assetPath: 'assets/models/wings_angel.glb'),
];