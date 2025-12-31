import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/portfolio_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_tools.dart';

class PortfolioTab extends StatelessWidget {
  const PortfolioTab({super.key});

  // نفس قائمة القطاعات
  static const List<String> industries = [
     'نتائج الحملات الإعلانية',
  'نتائج تحسين محركات البحث',
  'معرض تصاميمنا',
  'أعمال قسم إدارة وسائل التواصل الأجتماعى',
  ];

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'عمل',
      collection: 'portfolio',
      onAddPressed: () async {
        await showPortfolioForm(context, doc: null);
      },
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final imageCount =
            d['images'] is List ? (d['images'] as List).length : 0;
        final hasPdf = (d['pdfUrl'] ?? '').toString().isNotEmpty;

        return Card(
          color: AppColors.secondaryColor.withOpacity(0.2),
          child: ListTile(
            title: AppText(title: d['title'] ?? 'عمل'),
            subtitle: AppText(
              title:
                  'قطاع: ${d['industry'] ?? '-'} • صور: $imageCount • ملف: ${hasPdf ? "موجود" : "لا يوجد"}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await showPortfolioForm(context, doc: doc);
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'portfolio',
                    docId: doc.id,
                    title: 'حذف عمل',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
