import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../services/dashboard_service.dart';
import '../widgets/formation_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _dashboardService.getDashboardData(userId);
    if (data == null) {
      // If no data, try to seed once for demo purposes
      await _dashboardService.seedData(userId);
      final seededData = await _dashboardService.getDashboardData(userId);
      if (!mounted) return;
      setState(() {
        _dashboardData = seededData;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE9652B)));
    }

    if (_dashboardData == null) {
      return const Center(
          child: Text('Erreur lors du chargement des données.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatCards(),
              const SizedBox(height: 32),
              _buildFormationsHeader(),
              const SizedBox(height: 24),
              _buildFormationsGrid(),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildRecentParticipants()),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildGrowthChart()),
                ],
              ),
              const SizedBox(height: 32),
              _buildTopSkills(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final f = _dashboardData!.formateur;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: f.profilePicture.isNotEmpty
                ? Image.memory(
                    base64Decode(f.profilePicture),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      '${f.firstName[0]}${f.lastName[0]}'.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${f.firstName} ${f.lastName}',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  f.jobTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderStat(
              '${_dashboardData!.formations.length}', 'Formations'),
          _buildHeaderStat(
              '${_dashboardData!.stats['totalStudents']}', 'Étudiants'),
          _buildHeaderStat('${_dashboardData!.stats['avgRating']}', 'Note moy.',
              isRating: true),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, {bool isRating = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              if (isRating) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Color(0xFFE9652B), size: 20),
              ]
            ],
          ),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final stats = _dashboardData!.stats;
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Formations créées',
                '${stats['totalFormations']}',
                Icons.menu_book,
                const Color(0xFFE8F2FF),
                Colors.blue)),
        const SizedBox(width: 24),
        Expanded(
            child: _buildStatCard(
                'Étudiants inscrits',
                '${stats['totalStudents']}',
                Icons.people_outline,
                const Color(0xFFFFF1EB),
                const Color(0xFFE9652B))),
        const SizedBox(width: 24),
        Expanded(
            child: _buildStatCard('Note moyenne', '${stats['avgRating']} / 5',
                Icons.star_border, const Color(0xFFFFF8E5), Colors.amber)),
        const SizedBox(width: 24),
        Expanded(
            child: _buildStatCard(
                'Inscriptions ce mois',
                '+${stats['monthlyInscriptions']}',
                Icons.trending_up,
                const Color(0xFFEBFAF2),
                Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFormationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Mes formations',
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Créer une formation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE9652B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFormationsGrid() {
    final formations = _dashboardData!.formations;
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: formations
          .map((f) => FormationCard(
                formation: f,
                width: 320,
              ))
          .toList(),
    );
  }

  Widget _buildRecentParticipants() {
    final students = _dashboardData!.stats['recentStudents'] as List;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Participants récents',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...students.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Text(s['name'][0])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(s['course'],
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(s['time'],
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    final growth = _dashboardData!.stats['growthData'] as List;
    return Container(
      height: 380, // Explicit height for the chart container
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFFE9652B)),
              const SizedBox(width: 8),
              Text('Croissance des inscriptions',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(growth[value.toInt()]['month']),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                    growth.length,
                    (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: growth[i]['count'].toDouble(),
                              color: const Color(0xFFE9652B),
                              width: 40,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkills() {
    final skills = _dashboardData!.stats['topSkills'] as List;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compétences les plus enseignées',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...skills.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${s['count']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: s['count'] / 150,
                      backgroundColor: Colors.blue[50],
                      color: const Color(0xFF1A1C1E),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
