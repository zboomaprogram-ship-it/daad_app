// import 'package:adhd/core/utils/app_colors/app_colors.dart';
// import 'package:adhd/core/utils/dimensions/dimensions.dart';
// import 'package:flutter/material.dart';

// class CustomDropItem extends StatelessWidget {
//   const CustomDropItem({super.key, this.validator, this.onChanged, this.value, required this.hintText, this.value1, this.value2, this.dropText1, this.dropText2});

//   final String? Function(String?)? validator;
//   final void Function(String?)? onChanged;
//   final String? value;
//   final String hintText;
//   final String? value1;
//   final String? value2;
//   final String? dropText1;
//   final String? dropText2;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(right: 35.width, left: 35.width),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           color: AppColors.white,
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.darkGray.withOpacity(0.2),
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: DropdownButtonFormField<String>(
//           dropdownColor: AppColors.white,
//             value: value,
//             decoration: InputDecoration(
//               hintText: hintText,
//               focusColor: AppColors.offWhite,
//               fillColor: AppColors.offWhite,
//               hintStyle: TextStyle(
//                   color: AppColors.gray,
//                   fontFamily: 'Amiko',
//                   fontWeight: FontWeight.w900,
//                   fontSize: 16.width),
//               contentPadding: EdgeInsets.only(
//                   top: 15.height,
//                   left: 15.width,
//                   bottom: 15.height,
//                   right: 15.width),
//               border: OutlineInputBorder(
//                   borderSide: const BorderSide(
//                     color: AppColors.white,
//                     width: 3,
//                   ),
//                   borderRadius: BorderRadius.circular(30.width)),
//               focusedBorder: OutlineInputBorder(
//                 borderSide:
//                     const BorderSide(color: AppColors.offWhite, width: 3),
//                 borderRadius: BorderRadius.circular(50.width),
//               ),
//               enabledBorder: OutlineInputBorder(
//                   borderSide:
//                       const BorderSide(color: AppColors.offWhite, width: 3),
//                   borderRadius: BorderRadius.circular(30.width)),
//               focusedErrorBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Colors.red),
//                 borderRadius: BorderRadius.circular(30.width),
//               ),
//             ),
//             items:  [
//               DropdownMenuItem(value: value1, child: Text(dropText1!)),
//               DropdownMenuItem(value: value2, child: Text(dropText2!)),
//             ],
//             onChanged: onChanged,
//             validator: validator),
//       ),
//     );
//   }
// }
// /*
//  (value) {
//             if (value == null || value.isEmpty) {
//               return 'Please select gender';
//             }
//             return null;
//           },





//           (value) {
//             setState(() {
//               _selectedGender = value;
//             });
//           },





//            _selectedGender
// */