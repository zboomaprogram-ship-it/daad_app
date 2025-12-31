
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/reward_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../widgets/dashboard_tools.dart';

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'مكافأة',
      collection: 'rewards',
      onAddPressed: () => openRewardForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final requiredPoints = d['points'] ?? 0;

        return Card(
          color: AppColors.secondaryColor.withOpacity(0.2),
          child: ListTile(
            title: AppText(title: d['title'] ?? 'مكافأة'),
            subtitle: AppText(title: 'نقاط مطلوبة: $requiredPoints'),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openRewardForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'rewards',
                    docId: doc.id,
                    title: 'حذف مكافأة',
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
