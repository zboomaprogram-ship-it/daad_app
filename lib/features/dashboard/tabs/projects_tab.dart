import 'package:daad_app/features/dashboard/forms/projects_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../widgets/dashboard_tools.dart';
class ProjectsTab extends StatelessWidget {
  const ProjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'مشروع',
      collection: 'projects',
      onAddPressed: () => showProjectForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final status = d['status'] ?? 'pending';
        
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.business_center,
              color: _getStatusColor(status),
            ),
            title: Text(d['title'] ?? 'مشروع'),
            subtitle: Text(
              'الحالة: ${_getStatusLabel(status)} • المستخدم: ${d['userId'] ?? '-'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showProjectForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'projects',
                    docId: doc.id,
                    title: 'حذف مشروع',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'مكتمل ✓';
      case 'in_progress':
        return 'جاري العمل ⏳';
      case 'pending':
        return 'معلق ⏸';
      default:
        return status;
    }
  }
}