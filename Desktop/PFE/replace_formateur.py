import os
import re

file_path = r"c:\Users\yotub\Desktop\PFE\TrainerProfile-main\frontend\lib\screens\formateur_profile_screen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "import 'package:reactive_theme/reactive_theme.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:reactive_theme/reactive_theme.dart';")

# Fix scaffold background
content = content.replace("backgroundColor: const Color(0xFFF8F9FA),", "backgroundColor: Colors.transparent,")

# Fix _buildCompletenessCard
old_completeness = """  Widget _buildCompletenessCard() {
    final currentScore = _calculateCompleteness();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),"""
new_completeness = """  Widget _buildCompletenessCard() {
    final currentScore = _calculateCompleteness();
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white, borderRadius: BorderRadius.circular(24)),"""
content = content.replace(old_completeness, new_completeness)

# Fix title color in _buildCompletenessCard
old_completeness_title = """Text('Profil complété à',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),"""
new_completeness_title = """Text('Profil complété à',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),"""
content = content.replace(old_completeness_title, new_completeness_title)

# Fix _buildSectionCard
old_section = """  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),"""
new_section = """  Widget _buildSectionCard(String title, List<Widget> children) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white, borderRadius: BorderRadius.circular(24)),"""
content = content.replace(old_section, new_section)

# Fix title color in _buildSectionCard
old_section_title = """          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),"""
new_section_title = """          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),"""
content = content.replace(old_section_title, new_section_title)

# Fix _buildInputField
old_input = """  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = true, Widget? labelSuffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500, fontSize: 15)),"""
new_input = """  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = true, Widget? labelSuffix}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500, fontSize: 15, color: isDark ? Colors.white70 : const Color(0xFF1E293B))),"""
content = content.replace(old_input, new_input)

# Fix input field container color
old_input_bg = """          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),"""
new_input_bg = """          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),"""
content = content.replace(old_input_bg, new_input_bg)

# Fix text color in input field
old_input_text = """              style: GoogleFonts.outfit(color: const Color(0xFF1A1C1E)),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: 'Entrez ${label.toLowerCase()}',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),"""
new_input_text = """              style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1A1C1E)),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: 'Entrez ${label.toLowerCase()}',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontSize: 14),
              ),"""
content = content.replace(old_input_text, new_input_text)

# Fix darkColor in top text
content = content.replace("color: darkColor", "color: isDark ? Colors.white : darkColor")
old_top_text = """child: Text('Mon profil formateur',
                          style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: darkColor)),"""
# wait, "color: darkColor" is replaced, let's use regex
content = re.sub(r"color: darkColor", "color: ReactiveMode.isDarkMode(context) ? Colors.white : darkColor", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS")
