import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);
    final secondaryTextColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "HL",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? const Color(0xFF6200EE)
                              : const Color(0xFFB8860B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Habit Tracker",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              context,
              title: "Our Mission",
              content: "HabitLoop is designed by Odlix to help you build a better life through consistent habits. We believe that small, repeated actions lead to massive transformations. Our mission is to provide the most intuitive and premium habit tracking experience.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: "The Odlix Philosophy",
              content: "At Odlix, we focus on 'Hype' - High Performance, Yield, and Excellence. This app is more than just a list; it's a tool for peak productivity. Every element is crafted to motivate you and make your journey satisfying.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: "Privacy First",
              content: "Your data stays where it belongs: on your device. We don't store your habits or logs on any external servers. Your progress is personal and private.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    "Crafted with ❤️ by Odlix Team",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "© 2026 Odlix. All Rights Reserved.",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFF6200EE) : const Color(0xFFB8860B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.8),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
