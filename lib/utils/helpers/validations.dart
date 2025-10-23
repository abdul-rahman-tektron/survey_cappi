import 'package:flutter/material.dart';
import 'package:srpf/utils/extensions.dart';
import 'package:srpf/utils/regex.dart'; // Assuming you have a context.locale extension or similar

class Validations {
  Validations._();

  static String? requiredField(BuildContext context, String? value, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? context.locale.requiredField;
    }
    return null;
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.locale.emailRequired;
    }
    if (!RegExp(RegexPatterns.email).hasMatch(value.trim())) {
      return context.locale.invalidEmail;
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.locale.passwordRequired;
    }
    if (value.trim().length < 6) {
      return context.locale.passwordTooShort;
    }
    return null;
  }

  static String? validateMobile(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.locale.mobileRequired;
    }
    if (!RegExp(RegexPatterns.phone).hasMatch(value.trim())) {
      return context.locale.invalidMobile;
    }
    return null;
  }

  static String? validateContact1(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Contact Number 1 is required";
    }
    if (!RegExp(RegexPatterns.phone).hasMatch(value.trim())) {
      return context.locale.invalidMobile;
    }
    return null;
  }

  static String? validateContact2(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Contact Number 2 is required";
    }
    if (!RegExp(RegexPatterns.phone).hasMatch(value.trim())) {
      return context.locale.invalidMobile;
    }
    return null;
  }

  static String? validateUserID(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "User ID is required";
    }
    return null;
  }

  static String? validateCommunity(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Community is required";
    }
    return null;
  }

  static String? validateAddress(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Address is required";
    }
    return null;
  }

  static String? validateBuilding(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Building is required";
    }
    return null;
  }

  static String? validateBlock(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Block is required";
    }
    return null;
  }

  static String? validateTradeLicense(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Trade License Number is required";
    }
    if (!RegExp(RegexPatterns.alphanumeric).hasMatch(value.trim())) {
      return "Invalid Trade License Number";
    }

    return null;
  }

  static String? validateTradeLicenseExpiry(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Trade License Expiry is required";
    }

    return null;
  }

  static String? validateConfirmPassword(BuildContext context, String? oldValue, String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      return "Password Field is required";
    }
    if (oldValue != newValue) {
      return "Password mismatch";
    }
    return null;
  }

  static String? validateName(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.locale.fullName;
    }
    return null;
  }

  static String? validateBank(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Bank Name is required";
    }
    return null;
  }

  static String? validateBranch(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Branch is required";
    }
    return null;
  }

  static String? validateAccountNumber(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Account Number is required";
    }
    return null;
  }

  static String? validateIBanNumber(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "iBan Number is required";
    }
    return null;
  }

  static String? validateSwiftBicNumber(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Swift Bic Number is required";
    }
    return null;
  }
}
