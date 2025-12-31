import 'package:gsheets/gsheets.dart';

class GoogleSheetsService {
  // Get your credentials from Google Cloud Console
  // https://console.cloud.google.com/apis/credentials
  static const _credentials = r'''
  {
    "type": "service_account",
    "project_id": "YOUR_PROJECT_ID",
    "private_key_id": "YOUR_PRIVATE_KEY_ID",
    "private_key": "YOUR_PRIVATE_KEY",
    "client_email": "YOUR_CLIENT_EMAIL",
    "client_id": "YOUR_CLIENT_ID",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
  }
  ''';

  static const _spreadsheetId = 'YOUR_SPREADSHEET_ID';

  static Future<void> addUserToSheet(Map<String, dynamic> userData) async {
    try {
      final gsheets = GSheets(_credentials);
      final ss = await gsheets.spreadsheet(_spreadsheetId);
      
      var sheet = ss.worksheetByTitle('Users');
      sheet ??= await ss.addWorksheet('Users');

      // Add headers if first row
      final values = await sheet.values.allRows();
      if (values.isEmpty) {
        await sheet.values.insertRow(1, [
          'UID',
          'الاسم',
          'البريد',
          'الهاتف',
          'الدور',
          'تاريخ التسجيل',
        ]);
      }

      // Add user data
      await sheet.values.appendRow([
        userData['uid'],
        userData['name'],
        userData['email'],
        userData['phone'],
        userData['role'],
        userData['signup_date'],
      ]);
    } catch (e) {
      print('Google Sheets error: $e');
      // Don't throw - let app continue even if sheets fails
    }
  }
}