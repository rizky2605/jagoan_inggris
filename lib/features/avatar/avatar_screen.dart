import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:lottie/lottie.dart'; 

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

  // Variabel Preview (ID Item)
  String? _previewBody;
  String? _previewHead;
  String? _previewWings;
  String? _previewEffect;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  // Helper untuk mendapatkan path aset berdasarkan ID
  String _getAssetPath(String id, ItemCategory cat) {
    try {
      var item = shopCatalog.firstWhere((i) => i.id == id && i.category == cat);
      return item.assetPath;
    } catch (e) {
      if (cat == ItemCategory.body) return 'assets/models/avatar.glb';
      if (cat == ItemCategory.head) return ''; 
      if (cat == ItemCategory.wings) return ''; 
      if (cat == ItemCategory.effect) return 'https://lottie.host/98205738-9999-4444-8888-123456789012/fireball.json';
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

        _previewBody ??= user.equippedLoadout['body'];
        _previewHead ??= user.equippedLoadout['head']; 
        _previewWings ??= user.equippedLoadout['wings'];
        _previewEffect ??= user.equippedLoadout['effect'];

        return Row(
          children: [
            // --- KIRI: AVATAR 3D PREVIEW (40%) ---
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [const Color(0xFF2A0045), Colors.black.withValues(alpha: 0.9)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: -30,
                        child: Container(
                          width: 150, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.4), blurRadius: 50, spreadRadius: 10)],
                          ),
                        ),
                      ),
                      
                      ModelViewer(
                        key: ValueKey('preview_$_previewBody'), 
                        src: _getAssetPath(_previewBody!, ItemCategory.body), 
                        animationName: 'idle', 
                        autoPlay: true,
                        autoRotate: true,
                        cameraControls: true, 
                        backgroundColor: Colors.transparent,
                        exposure: 8,
                        disableZoom: true,
                        minCameraOrbit: "auto 90deg auto", 
                        maxCameraOrbit: "auto 90deg auto",
                        cameraTarget: "0.0m 0.5m 0m",
                      ),

                      if (_previewEffect != null)
                        Positioned(
                          bottom: 50,
                          child: IgnorePointer( 
                            child: Lottie.network(
                              _getAssetPath(_previewEffect!, ItemCategory.effect),
                              width: 150, height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            ),
                          ),
                        ),

                      if (_hasChanges(user))
                        Positioned(
                          top: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 10)]),
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
                  Container(
                    height: 60, 
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 8),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(color: const Color(0xFFBD00FF), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.4), blurRadius: 10)]),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4), 
                      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), 
                      tabs: const [
                        Tab(icon: Icon(Icons.accessibility_new, size: 18), text: "Body"),
                        Tab(icon: Icon(Icons.school, size: 18), text: "Head"),
                        Tab(icon: Icon(Icons.wind_power, size: 18), text: "Wings"),
                        Tab(icon: Icon(Icons.auto_awesome, size: 18), text: "Effect"),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12, bottom: 12),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildNeonGrid(user, ItemCategory.body),
                            _buildNeonGrid(user, ItemCategory.head),
                            _buildNeonGrid(user, ItemCategory.wings),
                            _buildNeonGrid(user, ItemCategory.effect),
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

  bool _hasChanges(UserModel user) {
    return _previewBody != user.equippedLoadout['body'] ||
           _previewHead != user.equippedLoadout['head'] ||
           _previewWings != user.equippedLoadout['wings'] ||
           _previewEffect != user.equippedLoadout['effect'];
  }

  Widget _buildNeonGrid(UserModel user, ItemCategory category) {
    List<ItemModel> items = shopCatalog.where((i) => i.category == category).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 40),
            SizedBox(height: 8),
            Text("Kategori Kosong", style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 0.68, 
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildNeonCard(user, items[index]);
      },
    );
  }

  Widget _buildNeonCard(UserModel user, ItemModel item) {
    bool isOwned = user.ownedItems.contains(item.id) || 
                   (item.category == ItemCategory.effect && user.unlockedEffects.contains(item.id));
                   
    String dbKey = item.category.name; 
    bool isEquipped = user.equippedLoadout[dbKey] == item.id;
    
    bool isPreviewing = false;
    if (item.category == ItemCategory.body && _previewBody == item.id) isPreviewing = true;
    if (item.category == ItemCategory.head && _previewHead == item.id) isPreviewing = true;
    if (item.category == ItemCategory.wings && _previewWings == item.id) isPreviewing = true;
    if (item.category == ItemCategory.effect && _previewEffect == item.id) isPreviewing = true;

    Color themeColor = item.rarityColor.withValues(alpha: 0.3);
    if (isEquipped) themeColor = Colors.greenAccent.withValues(alpha: 0.5);
    else if (isPreviewing) themeColor = Colors.amber.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (item.category == ItemCategory.body) _previewBody = item.id;
          if (item.category == ItemCategory.head) _previewHead = item.id;
          if (item.category == ItemCategory.wings) _previewWings = item.id;
          if (item.category == ItemCategory.effect) _previewEffect = item.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF252535),
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(
            color: isPreviewing || isEquipped ? Colors.white : themeColor, 
            width: isPreviewing || isEquipped ? 2 : 1
          ),
          boxShadow: isPreviewing || isEquipped ? [
            BoxShadow(color: themeColor, blurRadius: 12, spreadRadius: 1)
          ] : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 2, right: 2),
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
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6), 
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [themeColor.withValues(alpha: 0.15), Colors.transparent]
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  // [FIX 1] Mengganti Icons.3d_rotation dengan Icons.view_in_ar
                  child: item.category == ItemCategory.effect 
                    ? Lottie.network(item.assetPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.auto_awesome, color: Colors.white24))
                    : (item.assetPath.endsWith('.glb') 
                        ? const Icon(Icons.view_in_ar, color: Colors.white24, size: 30) 
                        : Image.asset(item.assetPath, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.help, color: Colors.white24))),
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                if (!isOwned && user.gold >= item.price) {
                  _showPurchaseDialog(item, user);
                } else if (isOwned && !isEquipped) {
                  _firestoreService.equipItem(uid, item.category.name, item.id);
                  
                  setState(() {
                      if (item.category == ItemCategory.body) _previewBody = item.id;
                      if (item.category == ItemCategory.head) _previewHead = item.id;
                      if (item.category == ItemCategory.wings) _previewWings = item.id;
                      if (item.category == ItemCategory.effect) _previewEffect = item.id;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8), 
                decoration: BoxDecoration(
                  color: isEquipped ? Colors.green.withValues(alpha: 0.2) 
                        : (isOwned ? Colors.blue.withValues(alpha: 0.2) 
                        : Colors.amber.withValues(alpha: 0.2)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                ),
                child: Text(
                  isEquipped ? "DIPAKAI" 
                  : (isOwned ? "PAKAI" : "${item.price} G"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9, 
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Harga: ${item.price} Gold", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text("Sisa Gold: ${user.gold - item.price}", style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              Navigator.pop(ctx);
              // [FIX 2] Menambahkan parameter category agar FirestoreService tahu ini beli Efek atau Item
              await _firestoreService.purchaseItem(uid, item.id, item.price, category: item.category.name);
            }, 
            child: const Text("BELI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}