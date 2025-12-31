import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import '../forms/deal_form.dart';
import '../widgets/dashboard_tools.dart';
 
class DealsWheelTab extends StatelessWidget {
  const DealsWheelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'عنصر عرض',
      collection: 'deals_wheel',
      onAddPressed: () => showDealForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final label = d['label'] ?? 'عنصر';
        final discount = d['discountPercent'] ?? 0;
        final isActive = d['isActive'] ?? false;
        
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.redeem,
              color: isActive ? Colors.green : Colors.grey,
            ),
            title: Text(label),
            subtitle: Text('خصم: $discount% • ${isActive ? "مفعل" : "معطل"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showDealForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'deals_wheel',
                    docId: doc.id,
                    title: 'حذف عنصر',
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