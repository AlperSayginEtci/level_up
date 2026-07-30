import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player_stats.dart';

class StatRadarChart extends StatelessWidget {
  final PlayerStats stats;

  const StatRadarChart({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Statların en yüksek değerini bularak grafiğin maksimum sınırını belirliyoruz.
    // Minimum 10 yapıyoruz ki düşük seviyelerde grafik çok küçük görünmesin.
    final maxStat = [
      stats.strength,
      stats.vitality,
      stats.agility,
      stats.intelligence,
      stats.sense
    ].reduce((a, b) => a > b ? a : b).toDouble();
    
    final maxY = maxStat < 10 ? 10.0 : maxStat + 2;

    return AspectRatio(
      aspectRatio: 1.2,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: showingDataSets(maxY),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.white24, width: 1.5),
          titlePositionPercentageOffset: 0.1,
          titleTextStyle: const TextStyle(
            color: Colors.blueAccent, // Neon mavi teması
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
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOutCirc,
      ),
    );
  }

  List<RadarDataSet> showingDataSets(double maxY) {
    return [
      RadarDataSet(
        fillColor: Colors.blueAccent.withOpacity(0.4),
        borderColor: Colors.blueAccent,
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
