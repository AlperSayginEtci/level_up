import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player_stats.dart';
import '../theme/app_theme.dart';

class StatRadarChart extends StatelessWidget {
  final PlayerStats stats;
  final bool isShadowMonarch;

  const StatRadarChart({super.key, required this.stats, this.isShadowMonarch = false});

  @override
  Widget build(BuildContext context) {
    // Mantıksal ölçeklendirme (Örn. en yüksek stat 25 ise maksimum sınır 40 olur)
    // Böylece stat 2 iken max'a çekilmiş gibi görünmez.
    final maxStat = [
      stats.strength,
      stats.vitality,
      stats.agility,
      stats.intelligence,
      stats.sense
    ].reduce((a, b) => a > b ? a : b).toDouble();
    
    // Her zaman 20'nin katları şeklinde bir üst limit belirliyoruz.
    // Başlangıç seviyesindeki düşük statların radarı doldurmasını engellemek için minimum 50 yapıyoruz.
    double maxY = ((maxStat ~/ 20) + 1) * 20.0;
    if (maxY < 50) {
      maxY = 50.0;
    }
    
    final primaryColor = AppTheme.getPrimaryColor(isShadowMonarch);

    return AspectRatio(
      aspectRatio: 1.2,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: showingDataSets(maxY, primaryColor),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.white24, width: 1.5),
          titlePositionPercentageOffset: 0.1,
          titleTextStyle: TextStyle(
            color: primaryColor, // Temaya göre dinamik renk
            fontSize: 9, // Küçültüldü
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return RadarChartTitle(text: 'STR', angle: angle);
              case 1:
                return RadarChartTitle(text: 'VIT', angle: angle);
              case 2:
                return RadarChartTitle(text: 'AGI', angle: angle);
              case 3:
                return RadarChartTitle(text: 'INT', angle: angle);
              case 4:
                return RadarChartTitle(text: 'SEN', angle: angle);
              default:
                return const RadarChartTitle(text: '');
            }
          },
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          tickBorderData: const BorderSide(color: Colors.white12),
          gridBorderData: const BorderSide(color: Colors.white12, width: 1),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  List<RadarDataSet> showingDataSets(double maxY, Color primaryColor) {
    return [
      // Görünmez maksimum sınır veri seti (Ölçeklendirmeyi sabitlemek için)
      RadarDataSet(
        fillColor: Colors.transparent,
        borderColor: Colors.transparent,
        entryRadius: 0,
        dataEntries: [
          RadarEntry(value: maxY),
          RadarEntry(value: maxY),
          RadarEntry(value: maxY),
          RadarEntry(value: maxY),
          RadarEntry(value: maxY),
        ],
        borderWidth: 0,
      ),
      // Gerçek oyuncu verileri
      RadarDataSet(
        fillColor: primaryColor.withValues(alpha: 0.4),
        borderColor: primaryColor,
        entryRadius: 3,
        dataEntries: [
          RadarEntry(value: stats.strength.toDouble()),
          RadarEntry(value: stats.vitality.toDouble()),
          RadarEntry(value: stats.agility.toDouble()),
          RadarEntry(value: stats.intelligence.toDouble()),
          RadarEntry(value: stats.sense.toDouble()),
        ],
        borderWidth: 2,
      ),
    ];
  }
}
