import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../models/formation_model.dart';
import 'package:reactive_theme/reactive_theme.dart';

class FormationCard extends StatefulWidget {
  final FormationModel formation;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double width;

  const FormationCard({
    super.key,
    required this.formation,
    this.onEdit,
    this.onDelete,
    this.width = 340,
  });

  @override
  State<FormationCard> createState() => _FormationCardState();
}

class _FormationCardState extends State<FormationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(_isHovered ? 0.9 : 0.7) : Colors.white.withOpacity(_isHovered ? 0.9 : 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? Colors.black.withOpacity(0.08)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: _isHovered ? 40 : 20,
                  offset: Offset(0, _isHovered ? 15 : 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with background and Level
                  Stack(
                    children: [
                      Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.formation.level,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(Icons.school_outlined,
                              color: Color(0xFFF97316), size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formation.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.formation.description,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[500],
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.formation.tags
                              .take(3)
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(t,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                                  ))
                              .toList(),
                        ),
                        if (widget.formation.date != null ||
                            (widget.formation.meetLink != null &&
                                widget.formation.meetLink!.isNotEmpty)) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (widget.formation.date != null) ...[
                                const Icon(Icons.event,
                                    size: 16, color: Color(0xFFF97316)),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.formation.date!.day.toString().padLeft(2, '0')}/${widget.formation.date!.month.toString().padLeft(2, '0')}/${widget.formation.date!.year} - ${widget.formation.time ?? ""}',
                                  style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                              if (widget.formation.meetLink != null &&
                                  widget.formation.meetLink!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.videocam_outlined,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                const Text(
                                  'Session Live',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        // Stats
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(widget.formation.duration,
                                style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13)),
                            const SizedBox(width: 16),
                            const Icon(Icons.people_outline,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${widget.formation.studentCount}',
                                style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13)),
                            const Spacer(),
                            ...List.generate(
                                5,
                                (i) => Icon(
                                      Icons.star,
                                      size: 14,
                                      color:
                                          i < (widget.formation.rating.round())
                                              ? Colors.orange
                                              : Colors.grey[300],
                                    )),
                            const SizedBox(width: 4),
                            Text('${widget.formation.rating}',
                                style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Modifier'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[200]!),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: widget.onDelete,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Color(0xFFEF4444), size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
