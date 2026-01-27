import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto do novo design Traki Entregador
/// Baseado nas especificações do Figma
class AppTextStyles {
  // Título principal da landing page
  static TextStyle landingTitle = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.171875,
  );

  // Subtítulo/descrição da landing page
  static TextStyle landingSubtitle = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.171875,
  );

  // Texto de botões primários
  static TextStyle buttonPrimary = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
    height: 1.171875,
  );

  // Texto de botões secundários
  static TextStyle buttonSecondary = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.171875,
  );
}
