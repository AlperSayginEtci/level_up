import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../providers/player_state_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';

class CreateQuestScreen extends StatefulWidget {
  final Quest? existingQuest;
  
  const CreateQuestScreen({super.key, this.existingQuest});

  @override
  State<CreateQuestScreen> createState() => _CreateQuestScreenState();
}

class _CreateQuestScreenState extends State<CreateQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _expController;
  late TextEditingController _targetController;
  
  QuestDifficulty _difficulty = QuestDifficulty.E;
  StatType _rewardStat = StatType.none;
  
  bool _isRecurring = true;
  List<int> _activeDays = [1, 2, 3, 4, 5, 6, 7]; // Default to every day
  
  // Quest Type
  bool _isProgressBased = false;
  bool _isChainQuest = false;
  
  // For Chain Quests
  List<SubQuest> _subQuests = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingQuest?.title ?? '');
    _descController = TextEditingController(text: widget.existingQuest?.description ?? '');
    _expController = TextEditingController(text: widget.existingQuest?.rewardExp.toString() ?? '50');
    _targetController = TextEditingController(text: widget.existingQuest?.targetProgress.toString() ?? '1');
    
    if (widget.existingQuest != null) {
      final q = widget.existingQuest!;
      _difficulty = q.difficulty;
      _rewardStat = q.rewardStat;
      _isRecurring = q.isRecurring;
      _activeDays = List.from(q.activeDays);
      _isProgressBased = q.isProgressBased;
      _isChainQuest = q.subQuests.isNotEmpty;
      _subQuests = List.from(q.subQuests);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _expController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _saveQuest() {
    if (_formKey.currentState!.validate()) {
      if (_isChainQuest && _subQuests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one Sub-Quest.')),
        );
        return;
      }

      final newQuest = Quest(
        id: widget.existingQuest?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descController.text,
        rewardExp: int.parse(_expController.text),
        difficulty: _difficulty,
        rewardStat: _rewardStat,
        isProgressBased: _isProgressBased && !_isChainQuest,
        targetProgress: _isProgressBased && !_isChainQuest ? int.parse(_targetController.text) : 1,
        isRecurring: _isRecurring,
        activeDays: _isRecurring ? _activeDays : [],
        subQuests: _isChainQuest ? _subQuests : [],
      );

      final controller = context.read<PlayerProgressAndStatsController>();
      if (widget.existingQuest != null) {
        // Edit existing logic (To be added to provider)
        // For now, remove old and add new
        controller.deleteQuest(widget.existingQuest!.id);
        controller.addNewQuestToPlayerBoard(newQuest);
      } else {
        controller.addNewQuestToPlayerBoard(newQuest);
      }

      Navigator.pop(context);
    }
  }

  void _addSubQuestDialog() {
    final subTitleCtrl = TextEditingController();
    final subExpCtrl = TextEditingController(text: '10');
    StatType subStat = StatType.none;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Sub-Quest'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subTitleCtrl,
                      decoration: const InputDecoration(labelText: 'Title (e.g. 10 Pushups)'),
                    ),
                    TextField(
                      controller: subExpCtrl,
                      decoration: const InputDecoration(labelText: 'Reward EXP'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StatType>(
                    initialValue: subStat,
                      decoration: const InputDecoration(labelText: 'Bonus Stat'),
                      items: StatType.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => subStat = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (subTitleCtrl.text.isNotEmpty) {
                      setState(() {
                        _subQuests.add(SubQuest(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: subTitleCtrl.text,
                          rewardExp: int.tryParse(subExpCtrl.text) ?? 10,
                          rewardStat: subStat,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  InputDecoration _buildInputDecoration(String label, bool isShadowMonarch) {
    final primary = AppTheme.getPrimaryColor(isShadowMonarch);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary.withValues(alpha: 0.5))),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary, width: 2)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Basic protection against editing full mechanics of System Quests
    final isSystem = widget.existingQuest?.isSystemQuest ?? false;
    final controller = context.watch<PlayerProgressAndStatsController>();
    final isShadowMonarch = controller.isShadowMonarchThemeActive;
    final primary = AppTheme.getPrimaryColor(isShadowMonarch);

    return SystemBackground(
      isShadowMonarch: isShadowMonarch,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Dark background
        appBar: AppBar(
          title: Text(
            widget.existingQuest == null ? 'SYSTEM: NEW QUEST' : 'SYSTEM: EDIT QUEST',
            style: AppTheme.systemTextStyle(
              isShadowMonarch,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: primary),
          elevation: 0,
        ),
        body: Container(
          margin: const EdgeInsets.all(16.0),
          decoration: AppTheme.systemCardDecoration(isShadowMonarch),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '[ QUEST DETAILS ]',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                enabled: !isSystem,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: _buildInputDecoration('Quest Title', isShadowMonarch),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                enabled: !isSystem,
                style: const TextStyle(color: Colors.white70),
                decoration: _buildInputDecoration('Description', isShadowMonarch),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              const Text(
                '[ REWARDS & DIFFICULTY ]',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expController,
                      enabled: !isSystem,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      decoration: _buildInputDecoration('Reward EXP', isShadowMonarch),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<QuestDifficulty>(
                      initialValue: _difficulty,
                      decoration: _buildInputDecoration('Rank', isShadowMonarch),
                      dropdownColor: AppTheme.getDarkColor(isShadowMonarch),
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      items: isSystem ? null : QuestDifficulty.values.map((d) {
                        return DropdownMenuItem(value: d, child: Text('Rank ${d.name}'));
                      }).toList(),
                      onChanged: isSystem ? null : (val) => setState(() => _difficulty = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<StatType>(
                initialValue: _rewardStat,
                decoration: _buildInputDecoration('Bonus Stat', isShadowMonarch),
                dropdownColor: AppTheme.getDarkColor(isShadowMonarch),
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                items: isSystem ? null : StatType.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text('+1 ${s.name.toUpperCase()}'));
                }).toList(),
                onChanged: isSystem ? null : (val) => setState(() => _rewardStat = val!),
              ),
              const SizedBox(height: 24),
              
              // Scheduling
              if (!isSystem) ...[
                const Text(
                  '[ QUEST TYPE & SCHEDULE ]',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Recurring Quest', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Does this repeat on certain days?', style: TextStyle(color: Colors.grey)),
                  activeTrackColor: primary.withValues(alpha: 0.5),
                  activeColor: primary,
                  contentPadding: EdgeInsets.zero,
                  value: _isRecurring,
                  onChanged: (val) => setState(() => _isRecurring = val),
                ),
                if (_isRecurring)
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                      final daysStr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final isSelected = _activeDays.contains(day);
                      return ChoiceChip(
                        label: Text(daysStr[day-1], style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
                        selected: isSelected,
                        selectedColor: primary.withValues(alpha: 0.4),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: isSelected ? primary : Colors.grey[800]!),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _activeDays.add(day);
                            } else {
                              _activeDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white24),
                ),
                
                // Quest Type
                SwitchListTile(
                  title: const Text('Chain Quest (Sub-Quests)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Multiple steps to complete', style: TextStyle(color: Colors.grey)),
                  activeTrackColor: primary.withValues(alpha: 0.5),
                  activeColor: primary,
                  contentPadding: EdgeInsets.zero,
                  value: _isChainQuest,
                  onChanged: (val) {
                    setState(() {
                      _isChainQuest = val;
                      if (val) _isProgressBased = false;
                    });
                  },
                ),
                
                if (!_isChainQuest)
                  SwitchListTile(
                    title: const Text('Progress Based', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Require X amount to complete (e.g. 10 pages)', style: TextStyle(color: Colors.grey)),
                    activeTrackColor: primary.withValues(alpha: 0.5),
                    activeColor: primary,
                    contentPadding: EdgeInsets.zero,
                    value: _isProgressBased,
                    onChanged: (val) => setState(() => _isProgressBased = val),
                  ),
              ],

              if (_isProgressBased || isSystem)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: _buildInputDecoration('Target Amount (e.g. 12)', isShadowMonarch),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),

              if (_isChainQuest) ...[
                const SizedBox(height: 24),
                const Text('[ SUB-QUESTS ]', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                ..._subQuests.map((sq) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ListTile(
                    title: Text(sq.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('+${sq.rewardExp} EXP', style: const TextStyle(color: Colors.greenAccent)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => _subQuests.remove(sq));
                      },
                    ),
                  ),
                )),
                OutlinedButton.icon(
                  onPressed: _addSubQuestDialog,
                  icon: Icon(Icons.add, color: primary),
                  label: Text('Add Sub-Quest', style: TextStyle(color: primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary),
                  ),
                )
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveQuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.2),
                    foregroundColor: primary,
                    side: BorderSide(color: primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('ACCEPT QUEST', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
