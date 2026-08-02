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

  List<Quest> _getQuestsForDate(DateTime date, List<Quest> allQuests) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final isPast = targetDay.isBefore(today);

    return allQuests.where((q) {
      if (isPast) {
        // For past days, only show quests that were ACTUALLY completed on that specific day
        return q.completedDates.any((d) => d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day);
      } else {
        // For today or future days
        if (q.isRecurring) {
          if (q.activeDays.isEmpty || q.activeDays.length == 7) return true; // Daily recurring
          return q.activeDays.contains(targetDay.weekday); // Specific days
        }
        // For one-time quests, show them on TODAY if they are not completed
        if (targetDay.isAtSameMomentAs(today) && !q.isCompleted) {
          return true;
        }
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final allQuests = playerController.availableQuests;
    final quests = _getQuestsForDate(_selectedDate, allQuests);
    
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isPast = selectedDay.isBefore(today);
    final isFuture = selectedDay.isAfter(today);
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
          _buildWeeklyCalendar(isShadowMonarch, allQuests),
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
                      return _buildPlannerQuestCard(quest, isPast, isFuture, isShadowMonarch, playerController);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isShadowMonarch, List<Quest> allQuests) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return SizedBox(
      height: 100, // Slightly increased height for the indicator dot
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, 
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3)); 
          final targetDay = DateTime(date.year, date.month, date.day);
          
          final isSelected = targetDay.isAtSameMomentAs(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day));
          
          final dayQuests = _getQuestsForDate(targetDay, allQuests);
          bool hasQuests = dayQuests.isNotEmpty;
          bool allCompleted = false;
          bool someCompleted = false;
          
          if (hasQuests) {
            if (targetDay.isBefore(today)) {
               allCompleted = true; // Only completed quests are returned for past days
               someCompleted = true;
            } else if (targetDay.isAtSameMomentAs(today)) {
               int completedCount = dayQuests.where((q) => q.isCompleted).length;
               someCompleted = completedCount > 0;
               allCompleted = completedCount == dayQuests.length;
            }
          }

          Color dotColor = Colors.transparent;
          if (hasQuests) {
            if (allCompleted) {
              dotColor = Colors.greenAccent;
            } else if (someCompleted) {
              dotColor = Colors.orangeAccent;
            } else if (targetDay.isAtSameMomentAs(today) || targetDay.isAfter(today)) {
              dotColor = Colors.grey;
            }
          }
                             
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
                  const SizedBox(height: 4),
                  // Progress Indicator Dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlannerQuestCard(Quest quest, bool isPast, bool isFuture, bool isShadowMonarch, PlayerProgressAndStatsController controller) {
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
            bool sqCompleted = isPast ? true : (isFuture ? false : sq.isCompleted);
            return ListTile(
              leading: Icon(
                sqCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: sqCompleted ? Colors.green : Colors.grey,
              ),
              title: Text(sq.title),
              trailing: Text('+${sq.rewardExp} EXP', style: const TextStyle(color: Colors.green)),
            );
          }).toList(),
        ),
      );
    }
    
    // Add completion button for active quests directly in Planner
    bool isCompleted = isPast ? true : (isFuture ? false : quest.isCompleted);
    
    return Container(
      decoration: isCompleted
          ? AppTheme.systemCardDecoration(isShadowMonarch).copyWith(
              color: Colors.green.withValues(alpha: 0.15),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            )
          : AppTheme.systemCardDecoration(isShadowMonarch),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(
          quest.title,
          style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18).copyWith(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(quest.description, style: TextStyle(color: Colors.grey[400])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: isCompleted
                  ? AppTheme.badgeDecoration(isShadowMonarch).copyWith(color: Colors.green.withValues(alpha: 0.3))
                  : AppTheme.badgeDecoration(isShadowMonarch),
              child: Text(
                isCompleted ? 'Completed' : 'Rank ${quest.difficulty.name}',
                style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : AppTheme.getPrimaryColor(isShadowMonarch)),
              ),
            ),
            if (!isCompleted && !isPast && !isFuture && !quest.isProgressBased) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  controller.completeSpecificQuestAndRewardPlayer(quest);
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
