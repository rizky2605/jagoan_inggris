import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart';
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

  // Variabel Preview
  String? _previewBody;
  String? _previewWeapon;
  String? _previewWings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  String _findAssetPath(String category, String? itemId) {
    if (itemId == null) {
      return '';
    }
    try {
      return shopCatalog.firstWhere((i) => i.id == itemId).assetPath;
    } catch (e) {
      return ''; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }

        UserModel user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);

        // Logic Preview
        _previewBody ??= user.equippedLoadout['body'];
        _previewWeapon ??= user.equippedLoadout['weapon'];
        _previewWings ??= user.equippedLoadout['wings'];

        String bodyAsset = _findAssetPath('body', _previewBody);

        return Row(
          children: [
            // --- KIRI: AVATAR 3D (40%) ---
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A0045),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Efek Glow Lantai
                      Positioned(
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.4), blurRadius: 50, spreadRadius: 10)
                            ]
                          ),
                        ),
                      ),
                      
                      // 3D Viewer
                      ModelViewer(
                        src: bodyAsset.isNotEmpty ? bodyAsset : 'assets/models/avatar_default.glb',
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                        ar: false,
                        disableZoom: false,
                      ),

                      // Label Preview
                      if (_previewBody != user.equippedLoadout['body'])
                        Positioned(
                          top: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 10)]
                            ),
                            child: const Text("PREVIEW MODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),

            // --- KANAN: KATALOG (60%) ---
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // 1. Tab Kategori
                  Container(
                    height: 45,
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFBD00FF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.4), blurRadius: 10)]
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(icon: Icon(Icons.person_outline, size: 20), text: null), 
                        Tab(icon: Icon(Icons.shield_outlined, size: 20), text: null), 
                        Tab(icon: Icon(Icons.wind_power, size: 20), text: null), 
                      ],
                    ),
                  ),

                  // 2. Grid Items
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12, bottom: 12),
                      // Background tipis di area grid
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildNeonGrid(user, 'body'),
                            _buildNeonGrid(user, 'weapon'),
                            _buildNeonGrid(user, 'wings'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- GRID BUILDER ---
  Widget _buildNeonGrid(UserModel user, String category) {
    List<ItemModel> items = shopCatalog.where((i) => i.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Item per baris
        childAspectRatio: 0.8, // Rasio sedikit lebih lebar (tadi 0.7 terlalu kurus)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildNeonCard(user, items[index]);
      },
    );
  }

  // --- KARTU ITEM (REVISI: IKON BESAR & RAPI) ---
  Widget _buildNeonCard(UserModel user, ItemModel item) {
    bool isOwned = user.ownedItems.contains(item.id);
    bool isEquipped = user.equippedLoadout[item.category] == item.id;
    
    bool isPreviewing = false;
    if (item.category == 'body' && _previewBody == item.id) {
      isPreviewing = true;
    }
    if (item.category == 'weapon' && _previewWeapon == item.id) {
      isPreviewing = true;
    }
    if (item.category == 'wings' && _previewWings == item.id) {
      isPreviewing = true;
    }

    // Warna Tema
    Color themeColor = Colors.white12;
    if (isEquipped) {
      themeColor = Colors.greenAccent;
    } else if (isPreviewing) {
      themeColor = Colors.amber;
    } else if (isOwned) {
      themeColor = Colors.cyanAccent;
    }

    String iconPath = 'assets/assets/images/icon_${item.category}.png'; 

    return GestureDetector(
      onTap: () {
        setState(() {
          if (item.category == 'body') _previewBody = item.id;
          if (item.category == 'weapon') _previewWeapon = item.id;
          if (item.category == 'wings') _previewWings = item.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF252535), // Warna kartu solid
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(
            color: themeColor.withValues(alpha: isPreviewing || isEquipped ? 1.0 : 0.3), 
            width: isPreviewing || isEquipped ? 2 : 1
          ),
          boxShadow: isPreviewing || isEquipped ? [
            BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)
          ] : [],
        ),
        child: Column(
          children: [
            // BAGIAN ATAS: Nama (Kecil di atas)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEquipped ? Colors.greenAccent : Colors.white70, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // BAGIAN TENGAH: Ikon (Memenuhi Ruang - Expanded)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6), // Jarak sedikit dari tepi
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Background glow halus di belakang ikon
                  gradient: RadialGradient(
                    colors: [
                      themeColor.withValues(alpha: 0.15),
                      Colors.transparent
                    ]
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding agar ikon tidak mepet border lingkaran
                  child: Image.asset(
                    iconPath,
                    fit: BoxFit.contain, // Memaksa gambar mengisi area seproporsional mungkin
                    errorBuilder: (ctx, err, stack) => Icon(
                      item.category == 'body' ? Icons.person : Icons.extension, 
                      color: Colors.white12, 
                      size: 30
                    ),
                  ),
                ),
              ),
            ),

            // BAGIAN BAWAH: Tombol Aksi (Full Width)
            GestureDetector(
              onTap: () {
                if (!isOwned && user.gold >= item.price) {
                  _showPurchaseDialog(item, user);
                } else if (isOwned && !isEquipped) {
                  _firestoreService.equipItem(uid, item.category, item.id);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  // Warna tombol berbeda sesuai status
                  color: isEquipped ? Colors.green.withValues(alpha: 0.2) 
                       : (isOwned ? Colors.blue.withValues(alpha: 0.2) 
                       : Colors.amber.withValues(alpha: 0.2)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)), // Rounded Bawah saja
                ),
                child: Text(
                  isEquipped ? "DIPAKAI" 
                  : (isOwned ? "PAKAI" : "${item.price} G"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: isEquipped ? Colors.greenAccent 
                         : (isOwned ? Colors.cyanAccent : Colors.amber)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(ItemModel item, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0045),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent)),
        title: Text("Beli ${item.name}?", style: const TextStyle(color: Colors.white)),
        content: Text("Harga: ${item.price} Gold", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.purchaseItem(uid, item.id, item.price);
            }, 
            child: const Text("BELI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}