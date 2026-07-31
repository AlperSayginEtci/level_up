import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';
import '../theme/app_theme.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _selectedDate = DateTime.now();

  String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isPast = selectedDay.isBefore(today);

    // Sadece Sistem Görevi olmayan ve her gün tekrarlanmayan (Spesifik günleri olan) görevleri filtrele
    final quests = playerController.availableQuests.where((q) {
      if (q.isSystemQuest) return false;
      
      if (isPast) {
        // Geçmişteki bir gün için, o gün tamamlanmışsa göster
        return q.completedDates.any((d) => d.year == selectedDay.year && d.month == selectedDay.month && d.day == selectedDay.day);
      } else {
        // Bugün veya gelecek için normal kurallar geçerli
        if (q.isRecurring && (q.activeDays.isEmpty || q.activeDays.length == 7)) return false;
        
        if (q.isRecurring && q.activeDays.isNotEmpty) {
          return q.activeDays.contains(_selectedDate.weekday);
        }
        return false; 
      }
    }).toList();

    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Quest Planner', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Haftalık / İleriye dönük yatay takvim
          _buildWeeklyCalendar(isShadowMonarch),
          const Divider(),
          
          Expanded(
            child: quests.isEmpty
                ? Center(
                    child: Text(
                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}\nNo specific quests scheduled.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      return _buildPlannerQuestCard(quest, isPast, isShadowMonarch);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isShadowMonarch) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Geçmişten 3 gün öncesi ile başlayıp ileriye 30 günlük bir planlayıcı şeridi oluştur
        itemCount: 30, 
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3)); 
          final isSelected = date.day == _selectedDate.day && 
                             date.month == _selectedDate.month && 
                             date.year == _selectedDate.year;
                             
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: isSelected 
                  ? AppTheme.systemCardDecoration(isShadowMonarch).copyWith(
                      border: Border.all(color: AppTheme.getPrimaryColor(isShadowMonarch), width: 2),
                    )
                  : AppTheme.systemCardDecoration(isShadowMonarch).copyWith(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayName(date.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildPlannerQuestCard(Quest quest, bool isPast, bool isShadowMonarch) {
    if (quest.subQuests.isNotEmpty) {
      return Container(
        decoration: AppTheme.systemCardDecoration(isShadowMonarch),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: ExpansionTile(
          title: Text(
            quest.title,
            style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(quest.description, style: TextStyle(color: Colors.grey[400])),
          children: quest.subQuests.map((sq) {
            return ListTile(
              leading: Icon(
                sq.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: sq.isCompleted ? Colors.green : Colors.grey,
              ),
              title: Text(sq.title),
              trailing: Text('+${sq.rewardExp} EXP', style: const TextStyle(color: Colors.green)),
            );
          }).toList(),
        ),
      );
    }
    
    return Container(
      decoration: AppTheme.systemCardDecoration(isShadowMonarch),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(
          quest.title,
          style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(quest.description, style: TextStyle(color: Colors.grey[400])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isPast || quest.isCompleted
              ? AppTheme.badgeDecoration(isShadowMonarch).copyWith(color: Colors.green.withValues(alpha: 0.3))
              : AppTheme.badgeDecoration(isShadowMonarch),
          child: Text(
            isPast ? 'Completed' : 'Rank ${quest.difficulty.name}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isPast || quest.isCompleted ? Colors.green : AppTheme.getPrimaryColor(isShadowMonarch)),
          ),
        ),
      ),
    );
  }
}
