import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Onboarding — editorial 3-page intro before login.
/// Same visual language as the rest of the app: white surface, single
/// lime accent, INTER 800 huge titles, tracked-uppercase eyebrows.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPageData> _buildPages(AppLocalizations l) => [
        _OnboardingPageData(
          eyebrow: l.onboardingPage1Eyebrow,
          title: l.onboardingPage1Title,
          subtitle: l.onboardingPage1Subtitle,
          icon: Icons.home_work_rounded,
        ),
        _OnboardingPageData(
          eyebrow: l.onboardingPage2Eyebrow,
          title: l.onboardingPage2Title,
          subtitle: l.onboardingPage2Subtitle,
          icon: Icons.auto_awesome_rounded,
        ),
        _OnboardingPageData(
          eyebrow: l.onboardingPage3Eyebrow,
          title: l.onboardingPage3Title,
          subtitle: l.onboardingPage3Subtitle,
          icon: Icons.handyman_rounded,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_v2_complete', true);
    if (mounted) context.go('/auth/login');
  }

  void _nextPage(int pagesLength) {
    HapticFeedback.selectionClick();
    if (_currentPage < pagesLength - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = _buildPages(l);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/isotipo_atrio_negro.png',
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        l.onboardingSkip,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AtrioColors.guestTextSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // ─── Pages ───
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(
                  data: pages[i],
                  pageNumber: i + 1,
                  totalPages: pages.length,
                ),
              ),
            ),

            // ─── Indicators + CTA ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final selected = _currentPage == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: selected
                              ? AtrioColors.guestTextPrimary
                              : AtrioColors.guestCardBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  // CTA pill
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _nextPage(pages.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtrioColors.guestTextPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast
                                ? l.onboardingGetStarted
                                : l.onboardingNext,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 17,
                            color: AtrioColors.neonLime,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single page ────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final int pageNumber;
  final int totalPages;
  const _OnboardingPage({
    required this.data,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          // ─── Hero visual ───
          Expanded(
            flex: 5,
            child: _Hero(icon: data.icon),
          ),
          // ─── Text section ───
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.eyebrow.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pageNumber.toString().padLeft(2, '0')} / ${totalPages.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.0,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: -0.1,
                    color: AtrioColors.guestTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero (minimal — just the icon) ─────────────────────────
class _Hero extends StatelessWidget {
  final IconData icon;
  const _Hero({required this.icon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final size = c.maxHeight.clamp(180.0, 360.0);
        return Center(
          child: Icon(
            icon,
            size: size * 0.26,
            color: const Color(0xFFD0D0D0),
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
