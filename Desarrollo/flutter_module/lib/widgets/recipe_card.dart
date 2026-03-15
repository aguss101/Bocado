import 'package:flutter/material.dart';
import 'macros_ribbon.dart';

class RecipeCardData {
  final String title;
  final String author;
  final String timeMin;
  final String pricePerServing;
  final String tag;
  final Color tagColor;
  final String imageUrl;
  final String authorAvatarUrl;
  final int calories;
  final String protein;
  final String carbs;
  final String fats;
  final int likes;
  final int comments;
  bool isSaved;

  RecipeCardData({
    required this.title,
    required this.author,
    required this.timeMin,
    required this.pricePerServing,
    required this.tag,
    required this.tagColor,
    required this.imageUrl,
    required this.authorAvatarUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.likes,
    required this.comments,
    this.isSaved = false,
  });
}

class RecipeCard extends StatefulWidget {
  final RecipeCardData data;

  const RecipeCard({super.key, required this.data});

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badges
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF334155),
                    child: const Icon(Icons.image, size: 48, color: Colors.white30),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    _Badge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_money, size: 14, color: primary),
                          Text(
                            widget.data.pricePerServing,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.data.tagColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.data.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.data.authorAvatarUrl),
                      onBackgroundImageError: (_, _) {},
                      backgroundColor: const Color(0xFF334155),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'por ${widget.data.author} • ${widget.data.timeMin} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                MacrosRibbon(
                  calories: widget.data.calories,
                  protein: widget.data.protein,
                  carbs: widget.data.carbs,
                  fats: widget.data.fats,
                ),

                const SizedBox(height: 12),

                // Actions row
                Row(
                  children: [
                    _ActionButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: _formatCount(widget.data.likes + (_isLiked ? 1 : 0)),
                      color: _isLiked ? Colors.red : null,
                      onTap: () => setState(() => _isLiked = !_isLiked),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: _formatCount(widget.data.comments),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Compartir',
                      onTap: () {},
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => widget.data.isSaved = !widget.data.isSaved),
                      child: Row(
                        children: [
                          Icon(
                            widget.data.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _Badge extends StatelessWidget {
  final Widget child;
  const _Badge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? defaultColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color ?? defaultColor,
            ),
          ),
        ],
      ),
    );
  }
}
