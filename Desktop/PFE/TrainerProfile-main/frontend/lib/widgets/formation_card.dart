import 'package:flutter/material.dart';
import '../models/formation_model.dart';

class FormationCard extends StatelessWidget {
  final FormationModel formation;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const FormationCard({
    super.key,
    required this.formation,
    this.width,
    this.height = 250, // Fixed height for a stable grid layout
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: formation.tags.take(3).map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFFE8F2FF),
                )).toList(),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${formation.studentCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  ...List.generate(5, (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < formation.rating ? Colors.orange : Colors.grey[200],
                  )),
                  const SizedBox(width: 4),
                  Text(
                    '${formation.rating}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
