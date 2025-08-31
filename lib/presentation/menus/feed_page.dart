// lib/presentation/menus/feed_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  double _sidebarXOffset = -250;
  bool _dragging = false;

  static const _emojis = ['👍', '💪', '🔥', '👏', '❤️'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (_) => _dragging = true,
        onHorizontalDragUpdate: (d) {
          if (_dragging) {
            setState(() {
              _sidebarXOffset = (_sidebarXOffset + d.delta.dx).clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _dragging = false;
          setState(() {
            _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          });
        },
        child: Stack(
          children: [
            // --- Conteúdo principal ---
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 0,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed:
                                () => setState(() => _sidebarXOffset = 0),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Feed do PT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ===== Frase do Dia (vinda do PT) =====
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream:
                            _firestore
                                .collection('feedPhrase')
                                .doc('singleton')
                                .snapshots(),
                        builder: (ctx, snap) {
                          final data = snap.data?.data();
                          final phrase =
                              (data?['text'] as String?)?.trim() ?? '';
                          if (phrase.isEmpty) {
                            // Sem frase do dia: não renderiza card
                            return const SizedBox.shrink();
                          }
                          return Card(
                            color: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      phrase,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // ===== Lista de Posts do PT =====
                      Expanded(
                        child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream:
                              _firestore
                                  .collection('posts')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                          builder: (ctx, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final docs = snap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "Nenhum post ainda.",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final doc = docs[i];
                                final data = doc.data();

                                final authorId =
                                    (data['authorId'] as String?) ?? '';
                                final text = (data['text'] as String?) ?? '';
                                final imageUrl = data['imageUrl'] as String?;
                                final createdAt =
                                    (data['createdAt'] as Timestamp?)?.toDate();

                                final reactions = Map<String, dynamic>.from(
                                  data['reactions'] ?? {},
                                );
                                final userReactions = Map<String, dynamic>.from(
                                  data['userReactions'] ?? {},
                                );

                                return Card(
                                  color: const Color(0xFF2C2C2C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Cabeçalho com avatar + nome do PT + data
                                        FutureBuilder<
                                          DocumentSnapshot<Map<String, dynamic>>
                                        >(
                                          future:
                                              _firestore
                                                  .collection('users')
                                                  .doc(authorId)
                                                  .get(),
                                          builder: (ctx, userSnap) {
                                            String displayName = 'PT';
                                            String? avatarUrl;

                                            if (userSnap.hasData &&
                                                userSnap.data!.data() != null) {
                                              final u = userSnap.data!.data()!;
                                              final firstName =
                                                  (u['firstName'] as String?) ??
                                                  '';
                                              final lastName =
                                                  (u['lastName'] as String?) ??
                                                  '';
                                              displayName =
                                                  '$firstName $lastName'
                                                          .trim()
                                                          .isEmpty
                                                      ? 'PT'
                                                      : '$firstName $lastName'
                                                          .trim();
                                              avatarUrl =
                                                  (u['profilePictureUrl']
                                                      as String?);
                                            }

                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor:
                                                      Colors.white24,
                                                  backgroundImage:
                                                      (avatarUrl != null &&
                                                              avatarUrl!
                                                                  .isNotEmpty)
                                                          ? NetworkImage(
                                                            avatarUrl!,
                                                          )
                                                          : null,
                                                  child:
                                                      (avatarUrl == null ||
                                                              avatarUrl!
                                                                  .isEmpty)
                                                          ? Text(
                                                            _initials(
                                                              displayName,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          )
                                                          : null,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        displayName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (createdAt != null)
                                                        Text(
                                                          DateFormat(
                                                            'dd/MM/yyyy HH:mm',
                                                          ).format(createdAt),
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.white54,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),

                                        if (text.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            text,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],

                                        if (imageUrl != null &&
                                            imageUrl.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          // >>> IMAGEM COM HERO + FULLSCREEN <<<
                                          _PostImageThumbnail(
                                            imageUrl: imageUrl,
                                            heroTag: 'postImage_$i',
                                          ),
                                        ],

                                        const SizedBox(height: 8),

                                        // ===== Reações (emojis) =====
                                        _buildReactionsRow(
                                          postId: doc.id,
                                          reactions: reactions,
                                          userReactions: userReactions,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overlay para fechar sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Animated Sidebar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _sidebarXOffset,
              top: 0,
              bottom: 0,
              child: Sidebar(
                width: 250,
                onClose: () => setState(() => _sidebarXOffset = -250),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsRow({
    required String postId,
    required Map<String, dynamic> reactions,
    required Map<String, dynamic> userReactions,
  }) {
    final uid = _auth.currentUser?.uid;
    final myEmoji = (uid != null) ? (userReactions[uid] as String?) : null;

    return Wrap(
      spacing: 8,
      children:
          _emojis.map((emoji) {
            final count = (reactions[emoji] as int?) ?? 0;
            final isMine = (myEmoji == emoji);

            return InkWell(
              onTap: () => _toggleReaction(postId: postId, emoji: emoji),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isMine ? Colors.teal : Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> _toggleReaction({
    required String postId,
    required String emoji,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final userReactions = Map<String, dynamic>.from(
        data['userReactions'] ?? {},
      );

      final prev = userReactions[uid] as String?;
      // Remover reação anterior (se existir)
      if (prev != null) {
        final prevCount = (reactions[prev] as int?) ?? 0;
        reactions[prev] = (prevCount - 1).clamp(0, 1 << 31);
        if (reactions[prev] == 0) reactions.remove(prev);
        userReactions.remove(uid);
      }

      // Se clicou no mesmo emoji -> só removeu. Se foi noutro -> adiciona novo.
      if (prev != emoji) {
        final newCount = (reactions[emoji] as int?) ?? 0;
        reactions[emoji] = newCount + 1;
        userReactions[uid] = emoji;
      }

      tx.update(ref, {'reactions': reactions, 'userReactions': userReactions});
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'PT';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Thumbnail do post com Hero e navegação para fullscreen
class _PostImageThumbnail extends StatelessWidget {
  const _PostImageThumbnail({required this.imageUrl, required this.heroTag});

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Abre página em fullscreen com Hero + zoom/pan
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black,
            pageBuilder:
                (_, __, ___) =>
                    _FullscreenImageView(imageUrl: imageUrl, heroTag: heroTag),
            transitionsBuilder:
                (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Viewer fullscreen com Hero + InteractiveViewer (pinch-to-zoom + pan)
class _FullscreenImageView extends StatefulWidget {
  const _FullscreenImageView({required this.imageUrl, required this.heroTag});

  final String imageUrl;
  final String heroTag;

  @override
  State<_FullscreenImageView> createState() => _FullscreenImageViewState();
}

class _FullscreenImageViewState extends State<_FullscreenImageView> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Alterna entre zoom 1x e 2.5x focado no ponto de toque
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      final tapPos = _doubleTapDetails?.localPosition ?? Offset.zero;
      final zoom = 2.5;
      final matrix =
          Matrix4.identity()
            ..translate(-tapPos.dx * (zoom - 1), -tapPos.dy * (zoom - 1))
            ..scale(zoom);
      _controller.value = matrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.98),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: (d) => _doubleTapDetails = d,
                onDoubleTap: _handleDoubleTap,
                child: Hero(
                  tag: widget.heroTag,
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            // Botão fechar
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Fechar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
