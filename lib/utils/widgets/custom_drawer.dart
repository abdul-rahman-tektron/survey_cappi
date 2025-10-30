import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/core/model/common/login/login_response.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/images.dart';
import 'package:srpf/utils/helpers/app_info_helper.dart';
import 'package:srpf/utils/helpers/screen_size.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/storage/hive_storage.dart';
import 'package:srpf/utils/storage/secure_storage.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int)? onItemSelected;

  const CustomDrawer({super.key, this.onItemSelected});

  @override
  Widget build(BuildContext context) => buildBody(context);

  Widget buildBody(BuildContext context) {
    final String? userJson = HiveStorageService.getUserData();
    final LoginDetail? user =
    userJson != null ? LoginDetail.fromJson(jsonDecode(userJson)) : null;

    final role = (user?.nRoleId.toString() ?? '').toLowerCase();
    bool isAdmin =( role == '1' || role.contains('1'));

    return SafeArea(
      child: Drawer(
        width: ScreenSize.width > 600
            ? ScreenSize.width * 0.55
            : ScreenSize.width * 0.7,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF171F89), // top
                Color(0xFF023C59), // middle
                Color(0xFF01121B), // bottom
              ],
              stops: [0.0, 0.001, 1.0],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Column(
            children: [
              _buildLogo(),
              10.verticalSpace,
              _buildGradientDivider(),
              _buildUserDetails(user),
              _buildGradientDivider(),
              15.verticalSpace,
              Expanded(child: _buildMenuList(context, isAdmin)),
              FutureBuilder<String>(
                future: AppInfoHelper.versionLabel(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    snapshot.data ?? '',
                    style: AppFonts.text14.regular.white.style.copyWith(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
              5.verticalSpace,
              _buildLogoutButton(context),
              15.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        AppImages.logoPrecisionWhite,
        height: ScreenSize.width > 600 ? 100 : 70,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildUserDetails(LoginDetail? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              AppImages.placeholder,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            ),
          ),
          15.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? "",
                  style: AppFonts.text16.bold.white.style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  user?.email ?? "",
                  style: AppFonts.text12.regular.white.style,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientDivider() {
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary.withOpacity(0.5),
            AppColors.primary,
            AppColors.primary.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, bool isAdmin) {
    final items = <List>[
      // [LucideIcons.settings, "Settings", 2],
      // 👇 show “Survey List” only for admin
      if (isAdmin) [LucideIcons.tableProperties, "Survey List", 3],
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return _buildDrawerItem(
          context,
          item[0] as IconData,
          item[1] as String,
          item[2] as int,
        );
      },
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, int value) {
    return ListTile(
      leading: Icon(icon, size: 25, color: AppColors.white),
      title: Text(title, style: AppFonts.text16.medium.white.style),
      onTap: () => _handleNavigation(context, value),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => logoutFunctionality(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.power, size: 25, color: AppColors.white),
            12.horizontalSpace,
            Text("Logout", style: AppFonts.text18.medium.white.style),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int value) {
    Navigator.pop(context);
    if (value == 3) {
      Navigator.pushNamed(context, AppRoutes.surveyList);
    } else if (value == 2) {
      // Navigator.pushNamed(context, AppRoutes.settings);
    }
  }

  Future<void> logoutFunctionality(BuildContext context) async {
    await SecureStorageService.clearData();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }
}