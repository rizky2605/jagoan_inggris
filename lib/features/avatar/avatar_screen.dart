import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart'; // Katalog Barang
import '../../core/services/firestore_service.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // Variabel untuk menyimpan preview item sementara (sebelum di-equip)
  String? _previewBody;
  String? _previewWeapon;
  String? _previewWings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Fungsi: Reset preview ke apa yang sedang dipakai user
  void _resetPreview(UserModel user) {
    setState(() {
      _previewBody = user.equippedLoadout['body'];
      _previewWeapon = user.equippedLoadout['weapon'];
      _previewWings = user.equippedLoadout['wings'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        UserModel user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);

        // Jika preview belum diset, set sesuai database
        _previewBody ??= user.equippedLoadout['body'];
        _previewWeapon ??= user.equippedLoadout['weapon'];
        _previewWings ??= user.equippedLoadout['wings'];

        // Cari file aset berdasarkan ID preview
        String bodyAsset = _findAssetPath('body', _previewBody);
        String weaponAsset = _findAssetPath('weapon', _previewWeapon);
        // Note: ModelViewer hanya support 1 model utama (glb). 
        // Idealnya weapon/wings digabung di Blender, tapi untuk simulasi kita ganti model utamanya saja.
        // Di sini kita akan menampilkan model 'Body' sebagai representasi utama.

        return Column(
          children: [
            // --- 1. AREA PREVIEW AVATAR (ATAS) ---
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Efek Glow di belakang
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 60)
                      ]
                    ),
                  ),
                  // Model 3D Viewer
                  ModelViewer(
                    // Kita pakai bodyAsset sebagai model utama
                    src: bodyAsset.isNotEmpty ? bodyAsset : 'assets/models/avatar_default.glb',
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: Colors.transparent,
                  ),
                  // Teks Info Preview
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24)
                      ),
                      child: const Text("Preview Mode", style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ),
                  )
                ],
              ),
            ),

            // --- 2. TAB KATEGORI (TENGAH) ---
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFBD00FF), // Ungu Neon
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: "BODY"),
                Tab(text: "WEAPON"),
                Tab(text: "WINGS"),
              ],
            ),

            // --- 3. GRID ITEM (BAWAH) ---
            Expanded(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItemGrid(user, 'body'),
                    _buildItemGrid(user, 'weapon'),
                    _buildItemGrid(user, 'wings'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET GRID ITEM ---
  Widget _buildItemGrid(UserModel user, String category) {
    // Filter barang sesuai kategori tab
    List<ItemModel> items = shopCatalog.where((i) => i.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 Kolom
        childAspectRatio: 0.85, // Rasio kartu
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(user, item);
      },
    );
  }

  // --- WIDGET KARTU BARANG ---
  Widget _buildItemCard(UserModel user, ItemModel item) {
    bool isOwned = user.ownedItems.contains(item.id);
    bool isEquipped = user.equippedLoadout[item.category] == item.id;
    bool canBuy = user.gold >= item.price;

    return GestureDetector(
      onTap: () {
        // Saat diklik, update preview (biar user bisa coba dulu sebelum beli)
        setState(() {
          if (item.category == 'body') _previewBody = item.id;
          if (item.category == 'weapon') _previewWeapon = item.id;
          if (item.category == 'wings') _previewWings = item.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Jika sedang dipakai: Hijau, Jika sedang di-preview: Kuning, Biasa: Abu
            color: isEquipped ? Colors.greenAccent : (
              (_previewBody == item.id || _previewWeapon == item.id) ? Colors.amber : Colors.white10
            ),
            width: isEquipped ? 2 : 1
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gambar/Ikon Barang
            Expanded(
              child: item.assetPath.isNotEmpty 
              ? Image.asset('assets/images/icon_${item.category}.png', errorBuilder: (_,__,___) => const Icon(Icons.checkroom, size: 40, color: Colors.white24)) 
              : const Icon(Icons.block, color: Colors.white24), // Ikon 'None'
            ),
            
            Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // TOMBOL AKSI
            if (isEquipped)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text("DIPAKAI", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              )
            else if (isOwned)
              ElevatedButton(
                onPressed: () async {
                  await _firestoreService.equipItem(uid, item.category, item.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item terpasang!")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(80, 30),
                ),
                child: const Text("PAKAI", style: TextStyle(fontSize: 10)),
              )
            else
              ElevatedButton(
                onPressed: canBuy ? () => _confirmPurchase(item) : null, // Disable jika uang kurang
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(80, 30),
                ),
                child: Text(
                  item.price == 0 ? "GRATIS" : "${item.price} G", 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- POPUP KONFIRMASI BELI ---
  void _confirmPurchase(ItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0045),
        title: const Text("Beli Item?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Yakin ingin membeli ${item.name} seharga ${item.price} Gold?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog dulu
              try {
                await _firestoreService.purchaseItem(uid, item.id, item.price);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pembelian Berhasil!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            }, 
            child: const Text("BELI", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Helper untuk mencari path aset dari ID
  String _findAssetPath(String category, String? itemId) {
    if (itemId == null) return '';
    try {
      return shopCatalog.firstWhere((i) => i.id == itemId).assetPath;
    } catch (e) {
      return ''; // Jika tidak ketemu (misal item 'none')
    }
  }
}