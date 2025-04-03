import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthorSocials extends StatelessWidget {
  const AuthorSocials({super.key});

  void _copyToClipboard(BuildContext context, String text, String platform) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$platform link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final iconColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect with the Author : Rohan Batra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SocialButton(
                  icon: Icons.child_care,
                  platform: 'GitHub',
                  link: 'https://github.com/rohanbatrain',
                  backgroundColor: backgroundColor,
                  iconColor: iconColor,
                  onTap: (link) => _copyToClipboard(context, link, 'GitHub'),
                ),
                _SocialButton(
                  icon: Icons.person,
                  platform: 'Portfolio',
                  link: 'https://rohanbatrain.github.io',
                  backgroundColor: backgroundColor,
                  iconColor: iconColor,
                  onTap: (link) => _copyToClipboard(context, link, 'Portfolio'),
                ),
                _SocialButton(
                  icon: Icons.work,
                  platform: 'LinkedIn',
                  link: 'https://linkedin.com/in/rohanbatrain',
                  backgroundColor: backgroundColor,
                  iconColor: iconColor,
                  onTap: (link) => _copyToClipboard(context, link, 'LinkedIn'),
                ),
                _SocialButton(
                  icon: Icons.movie,
                  platform: 'YouTube',
                  link: 'https://youtube.com/@rohanbatrain',
                  backgroundColor: backgroundColor,
                  iconColor: iconColor,
                  onTap: (link) => _copyToClipboard(context, link, 'YouTube'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String platform;
  final String link;
  final Color? backgroundColor;
  final Color? iconColor;
  final Function(String) onTap;

  const _SocialButton({
    required this.icon,
    required this.platform,
    required this.link,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTap(link),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                platform,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
