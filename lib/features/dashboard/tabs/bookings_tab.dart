import 'package:daad_app/features/dashboard/forms/booking_form.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
  import '../widgets/dashboard_tools.dart';
 
class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'حجز',
      collection: 'bookings',
      onAddPressed: () => showBookingForm(context),
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final type = d['type'] ?? '';
        final status = d['status'] ?? 'pending';
        
        return Card(
          child: ListTile(
            leading: const Icon(Icons.event_available),
            title: Text('حجز ${_getTypeLabel(type)}'),
            subtitle: Text(
              'الحالة: ${status} • المستخدم: ${d['userId'] ?? '-'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showBookingForm(context, doc: doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'bookings',
                    docId: doc.id,
                    title: 'حذف حجز',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'strategy_call':
        return 'استشارة استراتيجية';
      case 'consultation':
        return 'استشارة';
      default:
        return type;
    }
  }
}