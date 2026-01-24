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

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  // Variabel Preview
  String? _previewBody;
  String? _previewHead;
  String? _previewWings;
  String? _previewEffect;

  @override
  bool get wantKeepAlive => true; // Agar tidak reload saat pindah tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  String _getCombinedAvatarPath() {
    String body = _previewBody ?? 'avatar1';
    String head = _previewHead ?? 'none';
    String wings = _previewWings ?? 'none';
    
    if (body.isEmpty) body = 'avatar1';
    if (head.isEmpty) head = 'none';
    if (wings.isEmpty) wings = 'none';

    return 'assets/models/${body}_${head}_${wings}.glb';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }

        UserModel user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);

        _previewBody ??= user.equippedLoadout['body'] ?? 'avatar1';
        _previewHead ??= user.equippedLoadout['head'] ?? 'none'; 
        _previewWings ??= user.equippedLoadout['wings'] ?? 'none';
        _previewEffect ??= user.equippedLoadout['effect'] ?? 'fire';

        String currentAvatarPath = _getCombinedAvatarPath();

        return Row(
          children: [
            // --- KIRI: 3D PREVIEW (40%) ---
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
                      // Efek Lantai
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
                      
                      // 3D Model
                      ModelViewer(
                        key: ValueKey(currentAvatarPath), 
                        src: currentAvatarPath, 
                        animationName: 'stay', 
                        autoPlay: true,
                        autoRotate: true,
                        cameraControls: true, 
                        backgroundColor: Colors.transparent,
                        exposure: 8,
                        disableZoom: true,
                        minCameraOrbit: "auto 90deg auto", 
                        maxCameraOrbit: "auto 90deg auto",
                      ),

                      if (_hasChanges(user))
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
                  Container(
                    height: 60, 
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C), 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: Colors.white10)
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFBD00FF), 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.4), blurRadius: 10)]
                      ),
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
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2), 
                        borderRadius: BorderRadius.circular(20)
                      ),
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
    if (item.id == 'none') isOwned = true;

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
                  child: _buildItemIcon(item),
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                if (item.id == 'none') {
                   _firestoreService.equipItem(uid, item.category.name, item.id);
                   setState(() {
                      if (item.category == ItemCategory.head) _previewHead = item.id;
                      if (item.category == ItemCategory.wings) _previewWings = item.id;
                   });
                   return;
                }

                if (isOwned) {
                  if (!isEquipped) {
                    _firestoreService.equipItem(uid, item.category.name, item.id);
                    setState(() {
                      if (item.category == ItemCategory.body) _previewBody = item.id;
                      if (item.category == ItemCategory.head) _previewHead = item.id;
                      if (item.category == ItemCategory.wings) _previewWings = item.id;
                      if (item.category == ItemCategory.effect) _previewEffect = item.id;
                    });
                  }
                  return;
                }

                if (user.gold >= item.price) {
                  _showAnimatedDialog(context, item, user, isError: false);
                } else {
                  _showAnimatedDialog(context, item, user, isError: true);
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

  Widget _buildItemIcon(ItemModel item) {
    if (item.id == 'none') return const Icon(Icons.block, color: Colors.white24, size: 30);
    if (item.category == ItemCategory.effect) {
      return Lottie.asset(item.assetPath, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome));
    }
    return Image.asset(
      'assets/images/${item.id}.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        IconData fallbackIcon = Icons.help_outline;
        if (item.category == ItemCategory.body) fallbackIcon = Icons.person;
        if (item.category == ItemCategory.head) fallbackIcon = Icons.school;
        if (item.category == ItemCategory.wings) fallbackIcon = Icons.flight;
        return Icon(fallbackIcon, color: Colors.white24, size: 30);
      },
    );
  }

  // --- POPUP NEON DENGAN ANIMASI SCALE ---
  void _showAnimatedDialog(BuildContext context, ItemModel item, UserModel user, {required bool isError}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Container(); // Placeholder
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value), // Efek Bouncy Scale
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isError ? Colors.redAccent : Colors.cyanAccent, 
                width: 2
              )
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Animasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isError ? Colors.red : Colors.cyan).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.cancel_outlined : Icons.shopping_bag_outlined,
                    color: isError ? Colors.redAccent : Colors.cyanAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Judul
                Text(
                  isError ? "Uang Kurang!" : "Konfirmasi",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                
                // Pesan
                Text(
                  isError 
                    ? "Kamu butuh ${item.price - user.gold} Gold lagi."
                    : "Beli ${item.name} seharga ${item.price} Gold?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                
                const SizedBox(height: 24),
                
                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isError ? "Tutup" : "Batal", style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                    if (!isError) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 10,
                            shadowColor: Colors.cyanAccent.withValues(alpha: 0.4)
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _firestoreService.purchaseItem(uid, item.id, item.price, category: item.category.name);
                          },
                          child: const Text("Beli", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}