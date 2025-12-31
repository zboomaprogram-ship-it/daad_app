import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final TextEditingController bioController;

  final String? facebookUrl;
  final String? tiktokUrl;
  final String? snapchatUrl;
  final String? instagramUrl;

  final Function(String) onFacebookChanged;
  final Function(String) onTiktokChanged;
  final Function(String) onSnapchatChanged;
  final Function(String) onInstagramChanged;

  final bool isLoading;
  final Function() onSave;

  const ProfileForm({
    required this.nameController,
    required this.phoneController,
    required this.cityController,
    required this.addressController,
    required this.bioController,
    required this.facebookUrl,
    required this.tiktokUrl,
    required this.snapchatUrl,
    required this.instagramUrl,
    required this.onFacebookChanged,
    required this.onTiktokChanged,
    required this.onSnapchatChanged,
    required this.onInstagramChanged,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Name Field
        GlassTextField(
          controller: nameController,
          label: 'الاسم الكامل',
          icon: Icons.person_outline_rounded,
        ),
          SizedBox(height: 16.h
),

        // Phone Field
        GlassTextField(
          controller: phoneController,
          label: 'رقم الهاتف',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
          SizedBox(height: 16.h
),

        // City Field
        GlassTextField(
          controller: cityController,
          label: 'اسم المدينة',
          icon: Icons.location_city_outlined,
        ),
          SizedBox(height: 16.h
),

        // Address Field
        GlassTextField(
          controller: addressController,
          label: 'عنوان السكن',
          icon: Icons.home_outlined,
        ),
          SizedBox(height: 16.h
),

        // Bio Field
        GlassTextField(
          controller: bioController,
          label: 'لينك الصفحه',
          icon: Icons.link,
          maxLines: 3,
        ),
          SizedBox(height: 24.h
),

        // Social Media Section
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 8, bottom: 12),
            child: Text(
              'روابط التواصل الاجتماعي',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ),
        // Social Media Links
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SocialIconButton(
              icon: FontAwesomeIcons.facebook,
              isActive: facebookUrl != null && facebookUrl!.isNotEmpty,
              onPressed: () => _showSocialLinkDialog(context, 'Facebook', facebookUrl, onFacebookChanged),
            ),
            SocialIconButton(
              icon: FontAwesomeIcons.tiktok,
              isActive: tiktokUrl != null && tiktokUrl!.isNotEmpty,
              onPressed: () => _showSocialLinkDialog(context, 'TikTok', tiktokUrl, onTiktokChanged),
            ),
            SocialIconButton(
              icon: FontAwesomeIcons.snapchat,
              isActive: snapchatUrl != null && snapchatUrl!.isNotEmpty,
              onPressed: () => _showSocialLinkDialog(context, 'Snapchat', snapchatUrl, onSnapchatChanged),
            ),
            SocialIconButton(
              icon: FontAwesomeIcons.instagram,
              isActive: instagramUrl != null && instagramUrl!.isNotEmpty,
              onPressed: () => _showSocialLinkDialog(context, 'Instagram', instagramUrl, onInstagramChanged),
            ),
          ],
        ),
          SizedBox(height: 32.h
),

        // Save Button
        AppButton(
          btnText: 'حفظ التعديلات',
          onTap: isLoading ? null : onSave,
          isLoading: isLoading,
        ),
      ],
    );
  }

  void _showSocialLinkDialog(BuildContext context, String platform, String? currentUrl, Function(String) onSave) {
    final controller = TextEditingController(text: currentUrl ?? '');
    
    showDialog(
      context: context,  // Use the context passed here
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title: 'رابط $platform',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
                SizedBox(height: 16.h
),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل الرابط',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
                SizedBox(height: 24.h
),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const AppText(title:'إلغاء',),
                    ),
                  ),
                    SizedBox(width: 8.w
),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const AppText(title:'حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const SocialIconButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60.w
,
        height: 60.h
,
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r)
,
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 1.w
,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
