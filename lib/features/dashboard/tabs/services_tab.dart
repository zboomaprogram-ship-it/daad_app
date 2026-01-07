import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/service_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../widgets/dashboard_tools.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'خدمة',
      collection: 'services',
      onAddPressed: () => openServiceForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final title = d['title'] ?? 'خدمة';
        final price = (d['priceTiers'] is List && d['priceTiers'].isNotEmpty)
            ? d['priceTiers'][0]['price']
            : '-';
        final imageCount = d['images'] is List
            ? (d['images'] as List).length
            : 0;
        final category = d['category'] ?? '-';

        return Card(
          color: AppColors.secondaryColor.withOpacity(0.2),
          child: ListTile(
            leading: d['images'] != null && (d['images'] as List).isNotEmpty
                ? Image.network(
                    d['images'][0],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, color: AppColors.textColor),
                  )
                : const Icon(Icons.design_services, color: AppColors.textColor),
            title: AppText(title: title),
            subtitle: AppText(
              title: 'سعر: $price • صور: $imageCount • فئة: $category',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openServiceForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'services',
                    docId: doc.id,
                    title: 'حذف خدمة',
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
