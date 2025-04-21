import 'package:flutter/material.dart';
import '../models/audit.dart';

class ManageAuditScreen extends StatefulWidget {
  const ManageAuditScreen({Key? key}) : super(key: key);

  @override
  State<ManageAuditScreen> createState() => _ManageAuditScreenState();
}

class _ManageAuditScreenState extends State<ManageAuditScreen> {
  List<AuditSheet> auditSheets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text('Manage Audit'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildAuditList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newAuditSheet = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _CreateAuditSheetPage(),
            ),
          );
          if (newAuditSheet != null) {
            setState(() {
              auditSheets.add(newAuditSheet);
            });
          }
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit Sheets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${auditSheets.length} sheets available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditList() {
    if (auditSheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No audit sheets created yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: auditSheets.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final sheet = auditSheets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(sheet.name),
            subtitle: Text(
              'Created: ${_formatDate(sheet.createdAt)}\n${sheet.questions.length} questions',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editAuditSheet(sheet),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAuditSheet(sheet),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editAuditSheet(AuditSheet sheet) {
    _showAuditEditor(sheet);
  }

  void _showAuditEditor(AuditSheet? sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AuditEditorScreen(auditSheet: sheet),
      ),
    );
  }

  Future<void> _deleteAuditSheet(AuditSheet sheet) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Sheet'),
        content: Text('Are you sure you want to delete "${sheet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                auditSheets.remove(sheet);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Define a reusable widget for question entry
class QuestionEntry extends StatelessWidget {
  final TextEditingController questionController;
  final TextEditingController remarksController;
  final Function(int?) onScoreChanged;
  final VoidCallback onAttachPhoto;
  final int? selectedScore;

  const QuestionEntry({
    Key? key,
    required this.questionController,
    required this.remarksController,
    required this.onScoreChanged,
    required this.onAttachPhoto,
    this.selectedScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Write remarks (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Score:'),
            Radio<int>(value: 0, groupValue: selectedScore, onChanged: onScoreChanged),
            const Text('0'),
            Radio<int>(value: 1, groupValue: selectedScore, onChanged: onScoreChanged),
            const Text('1'),
            Radio<int>(value: 2, groupValue: selectedScore, onChanged: onScoreChanged),
            const Text('2'),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onAttachPhoto,
          child: const Text('Attach Photo'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Modify the main widget to use the QuestionEntry widget
class _AuditEditorScreen extends StatefulWidget {
  final AuditSheet? auditSheet;

  const _AuditEditorScreen({
    Key? key,
    this.auditSheet,
  }) : super(key: key);

  @override
  State<_AuditEditorScreen> createState() => _AuditEditorScreenState();
}

class _AuditEditorScreenState extends State<_AuditEditorScreen> {
  final List<QuestionEntry> questionEntries = [
    QuestionEntry(
      questionController: TextEditingController(),
      remarksController: TextEditingController(),
      onScoreChanged: (int? value) {},
      onAttachPhoto: () {},
    ),
  ];
  final List<AuditQuestion> savedQuestions = [];
  String? selectedZone;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.auditSheet == null ? 'Create Audit Sheet' : 'Edit Audit Sheet'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildZoneAndMonthPage(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _AddQuestionsPage(
                      savedQuestions: savedQuestions,
                      onAddQuestion: (AuditQuestion question) {
                        setState(() {
                          savedQuestions.add(question);
                        });
                      },
                    ),
                  ),
                );
              },
              child: const Text('Add Questions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneAndMonthPage() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Zone Name',
            border: OutlineInputBorder(),
          ),
          items: ['Zone A', 'Zone B', 'Zone C'].map((zone) => DropdownMenuItem<String>(
            value: zone,
            child: Text(zone),
          )).toList(),
          onChanged: (value) {
            setState(() {
              selectedZone = value;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Audit Month',
            border: OutlineInputBorder(),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                selectedDate = date;
              });
            }
          },
        ),
      ],
    );
  }
}

class _AddQuestionsPage extends StatefulWidget {
  final List<AuditQuestion> savedQuestions;
  final Function(AuditQuestion) onAddQuestion;

  const _AddQuestionsPage({
    Key? key,
    required this.savedQuestions,
    required this.onAddQuestion,
  }) : super(key: key);

  @override
  _AddQuestionsPageState createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<_AddQuestionsPage> {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  int? selectedScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Questions'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Write remarks (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Score:'),
                Radio<int>(
                  value: 0,
                  groupValue: selectedScore,
                  onChanged: (int? value) {
                    setState(() {
                      selectedScore = value;
                    });
                  },
                ),
                const Text('0'),
                Radio<int>(
                  value: 1,
                  groupValue: selectedScore,
                  onChanged: (int? value) {
                    setState(() {
                      selectedScore = value;
                    });
                  },
                ),
                const Text('1'),
                Radio<int>(
                  value: 2,
                  groupValue: selectedScore,
                  onChanged: (int? value) {
                    setState(() {
                      selectedScore = value;
                    });
                  },
                ),
                const Text('2'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newQuestion = AuditQuestion(
                  id: DateTime.now().toString(),
                  question: questionController.text,
                  section: 15, // Example section value
                  grade: selectedScore?.toDouble() ?? 0.0, // Default grade value
                );
                setState(() {
                  widget.onAddQuestion(newQuestion);
                  questionController.clear();
                  remarksController.clear();
                  selectedScore = null;
                });
              },
              child: const Text('Add New Question'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.savedQuestions.length,
                itemBuilder: (context, index) {
                  final question = widget.savedQuestions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Question ${index + 1}: ${question.question}'),
                      subtitle: Text('Score: ${question.grade}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // Implement edit logic
                              questionController.text = question.question;
                              selectedScore = question.grade.toInt();
                              setState(() {
                                widget.savedQuestions.removeAt(index);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                widget.savedQuestions.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, widget.savedQuestions);
                Navigator.pop(context);
              },
              child: const Text('Generate Audit Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAuditSheetPage extends StatefulWidget {
  @override
  _CreateAuditSheetPageState createState() => _CreateAuditSheetPageState();
}

class _CreateAuditSheetPageState extends State<_CreateAuditSheetPage> {
  String? selectedZone;
  DateTime? selectedDate;
  final List<AuditQuestion> questions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Audit Sheet'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                border: OutlineInputBorder(),
              ),
              items: ['Zone A', 'Zone B', 'Zone C'].map((zone) => DropdownMenuItem<String>(
                value: zone,
                child: Text(zone),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedZone = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Audit Month',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final newQuestions = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _AddQuestionsPage(
                      savedQuestions: questions,
                      onAddQuestion: (AuditQuestion question) {
                        setState(() {
                          questions.add(question);
                        });
                      },
                    ),
                  ),
                );
                if (newQuestions != null) {
                  setState(() {
                    questions.addAll(newQuestions);
                  });
                }
              },
              child: const Text('Add Questions'),
            ),
            const SizedBox(height: 16),
            if (questions.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  final newAuditSheet = AuditSheet(
                    name: 'Audit Sheet for $selectedZone',
                    createdAt: DateTime.now(),
                    questions: questions,
                    id: '',
                  );
                  Navigator.pop(context, newAuditSheet);
                },
                child: const Text('Generate Audit Sheet'),
              ),
          ],
        ),
      ),
    );
  }
} 