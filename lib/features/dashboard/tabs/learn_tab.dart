 
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/learn_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../widgets/dashboard_tools.dart';
 
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
            title: 'تعلم مع ضاد',
            collection: 'learnWithdaad',
            onAddPressed: () => openLearnForm(context),
            tileBuilder: (doc) {
              final d = doc.data() as Map<String, dynamic>;
              final imageCount = d['images'] is List ? (d['images'] as List).length : 0;
              return Card(
                color: AppColors.secondaryColor.withOpacity(0.2),
                child: ListTile(
                  title: AppText(title:d['title'] ?? 'تعلم'),
                  subtitle: AppText(title:
                    '${(d['body'] ?? '').toString()} • صور: $imageCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,color: Colors.blue,),
                        onPressed: () => openLearnForm(context, doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(
                          context: context,
                          collection: 'learnWithdaad',
                          docId: doc.id,
                          title: 'حذف تعلم',
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