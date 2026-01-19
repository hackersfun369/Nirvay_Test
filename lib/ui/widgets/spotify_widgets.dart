import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class SpotifyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isCircle;

  const SpotifyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isCircle ? 80 : 8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 160,
                  height: 160,
                  color: SpotifyColors.lightGrey,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: SpotifyColors.lightGrey,
                    shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isCircle ? null : BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: SpotifyColors.grey,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class SpotifyWelcomeCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const SpotifyWelcomeCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SpotifyColors.lightGrey,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(width: 56, height: 56, color: SpotifyColors.lightGrey),
              errorWidget: (context, url, error) => Container(
                width: 56,
                height: 56,
                color: SpotifyColors.lightGrey,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
