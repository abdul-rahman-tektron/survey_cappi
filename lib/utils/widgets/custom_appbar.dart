import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/images.dart';

/// Responsive single file AppBar
/// - Mobile + Tablet portrait friendly
/// - Logo scales to fill available title space (kept within safe max height)
/// - Optional Drawer button OR Back button
/// - Uses ScreenUtil for subtle scaling but does not rely on SizedBox.h/w
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDrawer;
  final bool showBackButton;
  final double? height; // allow override if needed

  const CustomAppBar({
    super.key,
    this.showDrawer = false,
    this.showBackButton = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Base heights (responsive caps)
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTabletPortrait = screenWidth >= 600 &&
        screenWidth < 900 &&
        MediaQuery.of(context).orientation == Orientation.portrait;

    // Toolbar height logic
    final double toolbarHeight = height ?? (isTabletPortrait ? 100.0 : 84.0);

    return PreferredSize(
      preferredSize: Size.fromHeight(toolbarHeight),
      child: AppBar(
        automaticallyImplyLeading: false, // we control leading explicitly
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: toolbarHeight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12.0),
          child: _buildLeading(context),
        ),
        // Title: make the image fill vertically within AppBar without overflow
        title: SizedBox(
          height: toolbarHeight * 0.6, // keep comfortable breathing room
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: Image.asset(
              AppImages.logoPrecisionWhite,
            ),
          ),
        ),
        // Example actions placeholder (uncomment if needed)
        // actions: [
        //   Padding(
        //     padding: const EdgeInsetsDirectional.only(end: 12.0),
        //     child: Icon(LucideIcons.bell, color: AppColors.white, size: 22.r),
        //   ),
        // ],
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTabletPortrait = screenWidth >= 600 &&
        screenWidth < 900 &&
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (showDrawer) {
      // Use Builder to get a context below Scaffold so openDrawer works
      return Builder(
        builder: (ctx) => InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Center(
            child: Icon(LucideIcons.menu, color: AppColors.white, size:  24.r),
          ),
        ),
      );
    }

    if (showBackButton) {
      return InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.maybePop(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.white.withOpacity(0.9)),
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(4),
          child: Icon(LucideIcons.arrowLeft, color: AppColors.white, size: isTabletPortrait ? 16.r: 20.r),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Size get preferredSize {
    // Provide a sensible default; actual height comes from build()
    return const Size.fromHeight(88.0);
  }
}
