import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Color System ──────────────────────────────────────────────────────
class AppColors {
  // Brand
  static const Color primary       = Color(0xFF8B0000);
  static const Color primaryDark   = Color(0xFF5C0000);
  static const Color primaryLight  = Color(0xFFB71C1C);
  static const Color accent        = Color(0xFFFF1744);
  static const Color accentDark    = Color(0xFFCC0022);
  static const Color accentLight   = Color(0xFFFF4466);
  static const Color accentNeon    = Color(0xFFFF2244);

  // Backgrounds
  static const Color bgDark        = Color(0xFF0A0A0A);
  static const Color bgMedium      = Color(0xFF111114);
  static const Color bgLight       = Color(0xFF1A1A1F);
  static const Color bgCard        = Color(0xFF161619);
  static const Color bgElevated    = Color(0xFF1E1E24);

  // Glass — single consolidated section
  static const Color glassBase     = Color(0x14FFFFFF);  // 8% white
  static const Color glassBg       = Color(0x0DFFFFFF);  // 5% white
  static const Color glassBorder   = Color(0x1AFFFFFF);
  static const Color glassHigh     = Color(0x26FFFFFF);  // 15% white (FIX: was duplicated)

  // Story ring colors
  static const Color storyUnseen         = Color(0xFF8B0000);
  static const Color storySeen           = Color(0xFF3A3A3A);
  static const Color storyGradientStart  = Color(0xFFFF1744);
  static const Color storyGradientEnd    = Color(0xFF8B0000);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBBBBBB);
  static const Color textMuted     = Color(0xFF666680);

  // Chat bubbles
  static const Color bubbleSelf       = Color(0x308B0000);
  static const Color bubbleSelfBorder = Color(0x50FF1744);
  static const Color bubbleOther      = Color(0x14FFFFFF);
  static const Color bubbleOtherBorder= Color(0x1FFFFFFF);

  // Status
  static const Color online        = Color(0xFF00C853);
  static const Color offline       = Color(0xFF616161);
  static const Color read          = Color(0xFF40C4FF);
  static const Color divider       = Color(0x1AFFFFFF);

  // Dev
  static const Color devGold       = Color(0xFFFFD700);

  AppColors._();
}

// ─── Gradient System ───────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0005), Color(0xFF0A0A0A), Color(0xFF0D000A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFF5C0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1F), Color(0xFF111114)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const RadialGradient splashGlow = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 0.9,
    colors: [Color(0x505C0000), Color(0x008B0000)],
  );
  static const LinearGradient drawerGradient = LinearGradient(
    colors: [Color(0xFF0D0005), Color(0xFF1A0008)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bubbleSelfGradient = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFF5C0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  AppGradients._();
}

// ─── Spacing & Sizing ──────────────────────────────────────────────────
class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;

  static const double btnH    = 44;
  static const double btnSmH  = 36;
  static const double btnXsH  = 30;
  static const double inputH  = 44;

  static const double radiusSm   = 8;
  static const double radiusMd   = 12;
  static const double radiusLg   = 16;
  static const double radiusXl   = 20;
  static const double radiusFull = 999;

  AppSpacing._();
}

// ─── Typography ───────────────────────────────────────────────────────
class AppText {
  static const TextStyle heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const TextStyle heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle small    = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle tiny     = TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static const TextStyle label    = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3);
  static const TextStyle caption  = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static const TextStyle accent   = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent);

  AppText._();
}

// ─── Theme ─────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme  => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.dark); // both dark

  static ThemeData _buildTheme(Brightness brightness) => ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.bgDark,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.primary,
      surface: AppColors.bgLight,
      error: Color(0xFFFF5252),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
      titleTextStyle: AppText.heading3,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.btnH),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(0, AppSpacing.btnSmH),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1),
        minimumSize: const Size(0, AppSpacing.btnH),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSpacing.btnSmH, AppSpacing.btnSmH),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(AppSpacing.sm),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
      ),
      hintStyle: AppText.small.copyWith(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFFF5252)),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 0.5,
      space: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),

    dialogTheme: DialogTheme(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      titleTextStyle: AppText.heading3,
      contentTextStyle: AppText.body.copyWith(color: AppColors.textSecondary),
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      dense: true,
      minLeadingWidth: 0,
      minVerticalPadding: AppSpacing.sm,
      titleTextStyle: AppText.bodyBold,
      subtitleTextStyle: AppText.small,
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : AppColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.accent.withOpacity(0.35)
              : AppColors.bgLight),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent),
      side: const BorderSide(color: AppColors.textMuted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      elevation: 4,
      textStyle: AppText.body,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgLight,
      selectedColor: AppColors.primary.withOpacity(0.3),
      labelStyle: AppText.small,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      side: const BorderSide(color: AppColors.glassBorder),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
      sizeConstraints: BoxConstraints.tightFor(width: 52, height: 52),
      iconSize: 22,
    ),

    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.divider,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: AppText.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );

  AppTheme._();
}
