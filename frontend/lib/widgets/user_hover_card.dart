import 'package:flutter/material.dart';

class UserHoverCard extends StatelessWidget {
  final LayerLink link;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final double? width;
  final Offset? followerOffset;
  final VoidCallback onMessage;
  final VoidCallback onClose;
  final VoidCallback onEnterCard;
  final VoidCallback onExitCard;
  const UserHoverCard({
    super.key,
    required this.link,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    this.width,
    this.followerOffset,
    required this.onMessage,
    required this.onClose,
    required this.onEnterCard,
    required this.onExitCard,
  });
  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: link,
      offset: followerOffset ?? const Offset(-10, -150),
      showWhenUnlinked: false,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: MouseRegion(
          onEnter: (_) => onEnterCard(),
          onExit: (_) => onExitCard(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: (width ?? 220)),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: avatarUrl.isNotEmpty
                            ? Image.network(avatarUrl, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 32, height: 32, color: Colors.grey.shade200, child: const Icon(Icons.person)))
                            : Container(width: 32, height: 32, color: Colors.grey.shade200, child: const Icon(Icons.person)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(displayName.isNotEmpty ? displayName : userId, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        onPressed: onClose, 
                        icon: const Icon(Icons.close, size: 16), 
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onMessage,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Enviar mensagem', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
