import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Palette monocromática con acento dorado
  static const Color cream = Color(0xFFFFFFFF);        // Blanco puro (fondo principal)
  static const Color parchment = Color(0xFFF4F4F4);   // Gris muy claro (tarjetas, inputs)
  static const Color parchmentDark = Color(0xFFEAEAEA); // Gris claro (hover, dividers)
  static const Color ink = Color(0xFF1A1A1A);          // Negro casi puro (texto principal)
  static const Color inkLight = Color(0xFF555555);     // Gris medio (texto secundario)
  static const Color inkFaint = Color(0xFF999999);     // Gris claro (placeholders, hints)
  static const Color accent = Color(0xFFB8860B);       // Dorado oscuro (dark goldenrod)
  static const Color accentDeep = Color(0xFF8B6508);   // Dorado más profundo
  static const Color accentLight = Color(0xFFDAA520);  // Dorado vibrante (goldenrod)
  static const Color danger = Color(0xFFCC3333);       // Rojo moderno
  static const Color dangerLight = Color(0xFFFFF0F0);  // Rojo muy suave
  static const Color success = Color(0xFF2E7D52);      // Verde
  static const Color successLight = Color(0xFFF0F7F4); // Verde muy suave
  static const Color warning = Color(0xFFB8860B);      // Dorado (mismo acento)
  static const Color warningLight = Color(0xFFFFF8E8); // Dorado muy suave
  static const Color border = Color(0xFFD4D4D4);       // Borde gris medio
  static const Color borderLight = Color(0xFFEEEEEE);  // Borde gris claro
  static const Color shadow = Color(0x1A1A1A1A);       // Sombra negra sutil
  static const Color white = Color(0xFFFFFFFF);

  // Status colors
  static const Color pendiente = Color(0xFFB8860B);    // Dorado
  static const Color pendienteLight = Color(0xFFFFF8E8);
  static const Color lista = Color(0xFF2E7D52);        // Verde
  static const Color listaLight = Color(0xFFF0F7F4);
  static const Color entregada = Color(0xFF555555);    // Gris medio
  static const Color entregadaLight = Color(0xFFF4F4F4);
  static const Color atrasada = Color(0xFFCC3333);     // Rojo
  static const Color atrasadaLight = Color(0xFFFFF0F0);
}
