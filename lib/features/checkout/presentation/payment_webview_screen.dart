import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen WebView that loads the Mercado Pago Checkout Pro page.
///
/// Intercepts redirect URLs (success/failure/pending) and returns
/// a [PaymentResult] via `Navigator.pop()`.
///
/// Usage:
/// ```dart
/// final result = await Navigator.of(context).push<PaymentResult>(
///   MaterialPageRoute(builder: (_) => PaymentWebViewScreen(
///     checkoutUrl: preference.initPoint,
///     bookingId: bookingId,
///   )),
/// );
/// ```
class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String bookingId;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.bookingId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onNavigationRequest: (request) {
            return _handleNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Intercept Mercado Pago redirect URLs.
  NavigationDecision _handleNavigation(String url) {
    // Check if this is one of our back_urls
    for (final pattern in MercadoPagoService.backUrlPatterns) {
      if (url.contains(pattern)) {
        // Parse the payment result from URL params
        final result = PaymentResult.fromUrl(url);
        debugPrint('[MP WebView] Payment result: ${result.status} '
            '(paymentId: ${result.paymentId})');

        // Return result to caller
        if (mounted) {
          Navigator.of(context).pop(result);
        }
        return NavigationDecision.prevent;
      }
    }

    // Allow all other navigations (MP checkout pages)
    return NavigationDecision.navigate;
  }

  /// User tapped back / close → treat as cancelled
  Future<bool> _onWillPop() async {
    final l = AppLocalizations.of(context);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.paymentWebCancelTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(l.paymentWebCancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.paymentWebKeepPaying,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AtrioColors.neonLimeDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.paymentWebExit,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AtrioColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop(
        const PaymentResult(status: 'cancelled'),
      );
    }
    return false; // We handle pop ourselves
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: _onWillPop,
            icon: const Icon(Icons.close, color: Colors.black87),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                l.checkoutPaymentWebTitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _isLoading
                ? LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF009EE3), // MP blue
                    minHeight: 3,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && _progress < 0.3)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF009EE3),
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.paymentWebLoading,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black54,
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
