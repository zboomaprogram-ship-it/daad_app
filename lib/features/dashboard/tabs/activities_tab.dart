
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/activity_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';


import '../widgets/dashboard_tools.dart';

class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'نشاط',
      collection: 'activities',
      onAddPressed: () => openActivityForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        return Card(
          color: AppColors.secondaryColor.withOpacity(0.2),
          child: ListTile(
            title: AppText(title: d['title'] ?? 'نشاط'),
            subtitle: AppText(
              title: 'نوع النشاط: ${d['type'] ?? ''} • نقاط: ${d['points'] ?? 0}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openActivityForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'activities',
                    docId: doc.id,
                    title: 'حذف نشاط',
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
