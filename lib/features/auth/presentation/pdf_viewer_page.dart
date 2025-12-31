import 'dart:io';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfContractPage extends StatefulWidget {
  final String pdfUrl;
  final String? title;
  final bool showAgreementButton;
  final VoidCallback? onAgree;

  const PdfContractPage({
    super.key,
    required this.pdfUrl,
    this.showAgreementButton = false,
    this.title,
    this.onAgree,
  });

  @override
  State<PdfContractPage> createState() => _PdfContractPageState();
}

class _PdfContractPageState extends State<PdfContractPage> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;
  bool hasScrolledToEnd = false;
  bool _disposed = false;
  double downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _disposed) return;
    setState(fn);
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      final request = http.Request('GET', uri);
      final response = await request.send();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw 'HTTP ${response.statusCode}';
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/contract_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;
      final bytes = <int>[];

      // Stream download with progress
      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          _safeSetState(() {
            downloadProgress = downloadedBytes / contentLength;
          });
        }
      }

      await file.writeAsBytes(bytes, flush: true);

      _safeSetState(() {
        localPath = file.path;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      _safeSetState(() {
        errorMessage = 'خطأ في تحميل الملف: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const GlassBackButton(),
        title: AppText(title: widget.title ?? 'عرض العقد',fontSize: 20,fontWeight: FontWeight.bold,),
        backgroundColor: AppColors.primaryColor,
        actions: [
          if (totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppText(
                  title: 'صفحة ${currentPage + 1} من $totalPages',
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? _buildShimmerLoading()
          : errorMessage != null
              ? _buildErrorState()
              : _buildPdfView(),
    );
  }

  Widget _buildShimmerLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PDF Icon shimmer
          ShimmerLoading(
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                size: 60.sp,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Loading text
          const AppText(
            title: 'جاري تحميل الملف...',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          SizedBox(height: 16.h),

          // Progress bar
          Container(
            width: 200.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: downloadProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          AppText(
            title: '${(downloadProgress * 100).toStringAsFixed(0)}%',
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),

          SizedBox(height: 24.h),

          // Shimmer page preview
          ShimmerLoading(
            child: Container(
              width: 250.w,
              height: 350.h,
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16.h),
          AppText(title: errorMessage!, color: Colors.red),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
                downloadProgress = 0.0;
              });
              _downloadAndSavePdf();
            },
            child: const AppText(title: 'إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    return Column(
      children: [
        Expanded(
          child: PDFView(
            filePath: localPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            onRender: (pages) {
              _safeSetState(() {
                totalPages = pages ?? 0;
              });
            },
            onPageChanged: (page, total) {
              _safeSetState(() {
                currentPage = page ?? 0;
                final t = total ?? totalPages;
                if (t > 0 && currentPage == (t - 1)) {
                  hasScrolledToEnd = true;
                }
              });
            },
            onError: (error) {
              _safeSetState(() {
                errorMessage = 'خطأ في عرض الملف: $error';
              });
            },
            onPageError: (page, error) {
              _safeSetState(() {
                errorMessage = 'خطأ في الصفحة ${page ?? '-'}: $error';
              });
            },
          ),
        ),
        if (widget.showAgreementButton) _buildAgreementButton(),
      ],
    );
  }

  Widget _buildAgreementButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasScrolledToEnd)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppText(
                      title: 'يرجى التمرير إلى نهاية العقد قبل الموافقة',
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasScrolledToEnd ? Colors.green : Colors.grey,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: hasScrolledToEnd ? () => widget.onAgree?.call() : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasScrolledToEnd ? Icons.check_circle : Icons.lock,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                AppText(
                  title: hasScrolledToEnd ? 'أوافق على العقد' : 'اقرأ العقد أولاً',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    final path = localPath;
    if (path != null) {
      Future.microtask(() {
        try {
          final f = File(path);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      });
    }
    super.dispose();
  }
}

// Shimmer Loading Widget
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}