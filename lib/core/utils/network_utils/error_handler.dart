import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:daad_app/core/widgets/app_text.dart';

/// Error types for better handling
enum ErrorType { noInternet, serverError, notFound, unauthorized, unknown }

/// Error handler utility
class ErrorHandler {
  static ErrorType getErrorType(dynamic error) {
    if (error is SocketException) {
      return ErrorType.noInternet;
    } else if (error.toString().contains('permission-denied')) {
      return ErrorType.unauthorized;
    } else if (error.toString().contains('not-found')) {
      return ErrorType.notFound;
    } else if (error.toString().contains('network')) {
      return ErrorType.noInternet;
    }
    return ErrorType.unknown;
  }

  static String getErrorMessage(ErrorType type) {
    switch (type) {
      case ErrorType.noInternet:
        return 'لا يوجد اتصال بالإنترنت\nالرجاء التحقق من اتصالك';
      case ErrorType.serverError:
        return 'حدث خطأ في الخادم\nالرجاء المحاولة لاحقاً';
      case ErrorType.notFound:
        return 'البيانات غير موجودة';
      case ErrorType.unauthorized:
        return 'ليس لديك صلاحية للوصول';
      case ErrorType.unknown:
        return 'حدث خطأ غير متوقع\nالرجاء المحاولة مرة أخرى';
    }
  }

  static IconData getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case ErrorType.serverError:
        return Icons.error_outline_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
      case ErrorType.unauthorized:
        return Icons.lock_outline_rounded;
      case ErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }
}

/// Error widget with retry button
class ErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;
  final String? customMessage;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final errorType = ErrorHandler.getErrorType(error);
    final message = customMessage ?? ErrorHandler.getErrorMessage(errorType);
    final icon = ErrorHandler.getErrorIcon(errorType);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: Colors.white.withOpacity(0.7)),
            ),
            SizedBox(height: 24.h),
            AppText(
              title: message,
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              textAlign: TextAlign.center,
              height: 1.5,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 8.w),
                  const AppText(
                    title: 'إعادة المحاولة',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

/// Empty state widget
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: Colors.white.withOpacity(0.5)),
            ),
            SizedBox(height: 24.h),
            AppText(
              title: message,
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 14.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                ),
                child: AppText(
                  title: actionText!,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
