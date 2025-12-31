import 'package:daad_app/features/dashboard/forms/artical_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../widgets/dashboard_tools.dart';
 
class ArticlesTab extends StatelessWidget {
  const ArticlesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
            title: 'مقال',
            collection: 'articles',
            onAddPressed: () => openArticleForm(context),
            tileBuilder: (doc) {
              final d = doc.data() as Map<String, dynamic>;
              final imageCount = d['images'] is List ? (d['images'] as List).length : 0;
              return Card(
                child: ListTile(
                  title: Text(d['title'] ?? 'مقال'),
                  subtitle: Text(
                    '${(d['body'] ?? '').toString()} • صور: $imageCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => openArticleForm(context, doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(
                          context: context,
                          collection: 'articles',
                          docId: doc.id,
                          title: 'حذف مقال',
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