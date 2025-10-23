import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/images.dart';
import 'package:srpf/screens/auth/login/login_notifier.dart';
import 'package:srpf/utils/widgets/common_background.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';

/// Single-column responsive login.
/// Requirement: **Only mobile + tablet (portrait)**. No landscape / wide desktop layout.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginNotifier(),
      child: Consumer<LoginNotifier>(
        builder: (context, loginNotifier, _) {
          return _buildBody(context, loginNotifier);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, LoginNotifier loginNotifier) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: CommonBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Orientation orientation = MediaQuery.of(context).orientation;
                final double rawWidth = constraints.maxWidth;

                // Tablet portrait: width between 600 and 900 AND in portrait
                final bool isTabletPortrait = rawWidth >= 600 && rawWidth < 900 && orientation == Orientation.portrait;

                // Shell width caps (no desktop)
                final double maxShellWidth = isTabletPortrait ? 760 : 480; // a bit wider on tablet portrait

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxShellWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isTabletPortrait ? 0 : 16.h).copyWith(top: 16.h, bottom: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLogoRow(),
                          24.verticalSpace,
                          _buildTitleBlock(center: true),
                          // Extra gap ONLY on tablet portrait
                          if (isTabletPortrait) 80.verticalSpace else 50.verticalSpace,
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                                child: _NarrowLayout(loginNotifier: loginNotifier, isTablet: isTabletPortrait),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(AppImages.logoTektronix, height: 44.h, fit: BoxFit.contain),
          ),
        ),
        12.horizontalSpace,
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Image.asset(AppImages.logoPrecisionBlack, height: 44.h, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBlock({required bool center}) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text("Welcome to", style: AppFonts.text18.regular.style, textAlign: center ? TextAlign.center : TextAlign.left),
        6.verticalSpace,
        Text(
          "Transport Survey",
          style: AppFonts.text22.bold.style.copyWith(color: AppColors.primary),
          textAlign: center ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.loginNotifier, required this.isTablet});
  final LoginNotifier loginNotifier;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    // Slightly wider card on tablet portrait
    final double cardMaxWidth = isTablet ? 520 : 480;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardMaxWidth),
        child: _LoginCard(loginNotifier: loginNotifier),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.loginNotifier});
  final LoginNotifier loginNotifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Form(
        key: loginNotifier.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Login to your account", style: AppFonts.text22.bold.style, textAlign: TextAlign.center),
            20.verticalSpace,
            CustomTextField(
              controller: loginNotifier.userNameController,
              fieldName: "User Name",
              textInputAction: TextInputAction.next,
            ),
            16.verticalSpace,
            CustomTextField(
              controller: loginNotifier.passwordController,
              fieldName: "Password",
              isPassword: true,
              textInputAction: TextInputAction.done,
            ),
            10.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RememberMe(loginNotifier: loginNotifier),
                _ForgetPassword(onTap: () {}),
              ],
            ),
            20.verticalSpace,
            CustomButton(
              text: "Login",
              isLoading: loginNotifier.isLoading,
              onPressed: () => loginNotifier.performLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.loginNotifier});
  final LoginNotifier loginNotifier;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => loginNotifier.toggleRememberMe(!loginNotifier.isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(6),
              color: loginNotifier.isChecked ? AppColors.white : Colors.transparent,
            ),
            child: loginNotifier.isChecked ? Icon(LucideIcons.check, size: 16, color: Colors.black) : null,
          ),
          8.horizontalSpace,
          Text("Remember me", style: AppFonts.text14.regular.style),
        ],
      ),
    );
  }
}

class _ForgetPassword extends StatelessWidget {
  const _ForgetPassword({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text("Forget Password", style: AppFonts.text14.medium.style),
      ),
    );
  }
}
