import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';

class _IntroPage {
  final String title;
  final String tag;
  final String body;
  final Color color;
  const _IntroPage(this.title, this.tag, this.body, this.color);
}

const _pages = [
  _IntroPage('Welcome to Digi5S', 'Digital 5S Management Platform',
      'Transform your workplace organization with our comprehensive digital 5S management solution designed for modern teams.',
      Color(0xFF1E3A8A)),
  _IntroPage('Team Management', 'Organize & Coordinate',
      'Efficiently manage your team members, assign roles, and coordinate zone activities for optimal 5S implementation.',
      Color(0xFF4CAF50)),
  _IntroPage('Task Management', 'Track & Execute',
      'Create, assign, and monitor 5S tasks across different zones. Track progress and ensure timely completion of activities.',
      Color(0xFF2196F3)),
  _IntroPage('Red Tag List', 'Identify & Resolve',
      'Mark and track items that need attention or removal. Streamline the sorting process with digital red tag management.',
      Color(0xFFF0326E)),
  _IntroPage('5S Audit Score', 'Measure & Improve',
      'Conduct comprehensive 5S audits, track scores, and generate detailed reports to monitor continuous improvement.',
      Color(0xFFFF9800)),
  _IntroPage('5S News', 'Stay Informed',
      'Keep your team updated with the latest 5S news, announcements, and best practices to maintain engagement.',
      Color(0xFF9C27B0)),
];

/// First-run walkthrough. Shown once; "Skip" or "Get Started" marks it seen.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(introSeenProvider.notifier).markSeen();
    if (mounted) context.go('/get-started');
  }

  void _go(int i) => _controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const _Backdrop(),
                  PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _IntroPageView(page: _pages[i]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: i == _index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index ? page.color : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_index > 0) ...[
                        Expanded(
                          flex: 4,
                          child: OutlinedButton.icon(
                            onPressed: () => _go(_index - 1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: page.color,
                              side: BorderSide(color: page.color.withOpacity(0.4), width: 1.5),
                              minimumSize: const Size.fromHeight(56),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            icon: const Icon(Icons.chevron_left, size: 20),
                            label: const Text('Previous', maxLines: 1, overflow: TextOverflow.fade, softWrap: false,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        flex: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(colors: [page.color, page.color.withOpacity(0.75)]),
                            boxShadow: [BoxShadow(color: page.color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                          ),
                          child: ElevatedButton(
                            onPressed: last ? _finish : () => _go(_index + 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(last ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Icon(last ? Icons.rocket_launch_outlined : Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!last)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        backgroundColor: Colors.grey.shade100,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      child: const Text('Skip Introduction', style: TextStyle(fontSize: 15)),
                    )
                  else
                    const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPageView extends StatelessWidget {
  const _IntroPageView({required this.page});
  final _IntroPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/images/digi5s_logo.png', width: 120, height: 120),
          const SizedBox(height: 60),
          Text(page.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: page.color, height: 1.15)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.10),
              border: Border.all(color: page.color.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(page.tag, style: TextStyle(color: page.color, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Text(page.body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, height: 1.5, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}

/// Faint grid and soft circles behind the pages.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(top: 100, left: -120, child: _circle(240)),
          Positioned(top: 110, right: -40, child: _circle(140)),
          Positioned(bottom: -80, right: -60, child: _circle(260)),
        ],
      ),
    );
  }

  Widget _circle(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.grey.shade200.withOpacity(0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
