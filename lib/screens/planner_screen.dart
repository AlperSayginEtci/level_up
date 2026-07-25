import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';

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
    
    // Sadece Sistem Görevi olmayan ve her gün tekrarlanmayan (Spesifik günleri olan) görevleri filtrele
    final quests = playerController.availableQuests.where((q) {
      if (q.isSystemQuest) return false;
      
      // Eğer her gün olan bir görevse (activeDays boşsa veya 7 gün seçiliyse) takvimde göstermeyelim, zaten anasayfada var.
      if (q.isRecurring && (q.activeDays.isEmpty || q.activeDays.length == 7)) return false;
      
      // Seçili tarihin haftanın gününe denk gelen görevleri listele
      if (q.isRecurring && q.activeDays.isNotEmpty) {
        return q.activeDays.contains(_selectedDate.weekday);
      }
      
      return false; 
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Planner'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Haftalık / İleriye dönük yatay takvim
          _buildWeeklyCalendar(),
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
                      return _buildPlannerQuestCard(quest);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
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
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurpleAccent : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.purpleAccent, width: 2) : null,
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



  Widget _buildPlannerQuestCard(Quest quest) {
    if (quest.subQuests.isNotEmpty) {
      return Card(
        color: Colors.grey[850],
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: Text(
            quest.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(quest.description),
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
    
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          quest.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(quest.description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Rank ${quest.difficulty.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
