import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildCollectionTab({
  required String title,
  required String collection,
  required VoidCallback onAddPressed,
  required Widget Function(DocumentSnapshot doc) tileBuilder,
}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryColor, AppColors.primaryColor],
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, // ✅ important for keyboard
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(collection).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: AppText(
                  title: 'خطأ: ${snapshot.error}',
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.white54),
                    SizedBox(height: 16.h),
                    AppText(
                      title: 'لا توجد $title بعد',
                      fontSize: 16,
                    ),
                  ],
                ),
              );
            }

            final keyboard = MediaQuery.of(context).viewInsets.bottom;

            return ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16.r,
                16.r,
                16.r,
                (16.r + keyboard), // ✅ push content up when keyboard opens
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: tileBuilder(docs[index]),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Builder(
        builder: (context) {
          final keyboard = MediaQuery.of(context).viewInsets.bottom;

          return Padding(
            // ✅ keep FAB above keyboard
            padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent.withOpacity(0.3),
                        Colors.transparent.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 1.w,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAddPressed,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 14.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8.w),
                            AppText(
                              title: 'إضافة $title',
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
