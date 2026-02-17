import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateLogModal extends StatefulWidget {
  const CreateLogModal({super.key});

  @override
  State<CreateLogModal> createState() => _CreateLogModalState();
}

class _CreateLogModalState extends State<CreateLogModal> {
  // --- Controllers & State ---
  final TextEditingController _coordinatorController = TextEditingController();
  final TextEditingController _staffInputController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _sheetController = TextEditingController();
  
  bool _isAuthorSameAsStaff = false;
  DateTime _selectedDate = DateTime.now();
  
  String? _selectedSite;
  final List<String> _sites = ["Site 1", "Site 2", "Site 3"];

  final List<String> _staffInvolved = [];
  final List<String> _selectedReasons = [];
  final List<Map<String, String>> _students = [
    {'name': '', 'time': '', 'returned': '', 'duration': ''}
  ];

  final List<String> _incidentOptions = [
    "Anti Social Behaviour to pupils",
    "Anti Social Behaviour to staff",
    "Anti Social Behaviour to property",
    "Violence/ Aggression to pupils",
    "Violence/ Aggression to staff",
    "Property damage",
    "Smoking",
    "Substance abuse",
    "Absenting",
    "Absconding",
    "Refusal to participate in lesson",
    "Refusal to participate in Activity",
    "Positive report"
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _coordinatorController.dispose();
    _staffInputController.dispose();
    _authorController.dispose();
    _dateController.dispose();
    _activityController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _addStaffMember(String name) {
    if (name.trim().isNotEmpty) {
      setState(() {
        _staffInvolved.add(name.trim());
        _staffInputController.clear();
        if (_isAuthorSameAsStaff && _staffInvolved.isNotEmpty) {
          _authorController.text = _staffInvolved.first;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 950),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 30, thickness: 2),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopFields(),
                        const SizedBox(height: 20),
                        _buildStaffSection(),
                        const SizedBox(height: 25),
                        _buildReasonDropdown(),
                        const SizedBox(height: 25),
                        _buildStudentSection(),
                        const SizedBox(height: 25),
                        _buildDescriptionFields(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Center(
      child: Text(
        "DUTY COORDINATOR LOG",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTopFields() {
    return Column(
      children: [
        // Row 1: Coordinator, Site, Date
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _coordinatorController,
                decoration: const InputDecoration(
                  labelText: "Duty Coordinator", 
                  prefixIcon: Icon(Icons.assignment_ind),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  labelText: "Site",
                  border: OutlineInputBorder(),
                ),
                items: _sites.map((site) => DropdownMenuItem(value: site, child: Text(site))).toList(),
                onChanged: (val) => setState(() => _selectedSite = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: "Date",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Activity/Lesson and Sheet No.
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(
                  labelText: "Activity / Lesson",
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _sheetController,
                decoration: const InputDecoration(
                  labelText: "Sheet No.",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Staff Involved", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._staffInvolved.map((staff) => Chip(
                label: Text(staff),
                onDeleted: () => setState(() => _staffInvolved.remove(staff)),
              )),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _staffInputController,
                  decoration: const InputDecoration(
                    hintText: "Add staff...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: _addStaffMember,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () => _addStaffMember(_staffInputController.text),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Incident Types (Multi-select):", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _incidentOptions.map((option) {
            final isSelected = _selectedReasons.contains(option);
            return FilterChip(
              label: Text(option, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.2),
              onSelected: (bool selected) {
                setState(() {
                  selected ? _selectedReasons.add(option) : _selectedReasons.remove(option);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pupils", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _students.add({'name': '', 'time': '', 'returned': '', 'duration': ''})),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text("Add Pupil"),
            ),
          ],
        ),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: IntrinsicColumnWidth()
          },
          children: [
            ..._students.asMap().entries.map((entry) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextFormField(decoration: const InputDecoration(hintText: "Name")),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextFormField(decoration: const InputDecoration(hintText: "Time")),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextFormField(decoration: const InputDecoration(hintText: "Ret.")),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextFormField(decoration: const InputDecoration(hintText: "Dur.")),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => _students.removeAt(entry.key)),
                )
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionFields() {
    return Column(
      children: [
        TextFormField(maxLines: 2, decoration: const InputDecoration(labelText: "Brief Description", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextFormField(maxLines: 2, decoration: const InputDecoration(labelText: "Actions taken by staff", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextFormField(maxLines: 2, decoration: const InputDecoration(labelText: "Outcome/ Consequence", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _authorController,
                readOnly: _isAuthorSameAsStaff,
                decoration: const InputDecoration(
                  labelText: "MIR Author", 
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: const Text("Use Lead Staff"),
              selected: _isAuthorSameAsStaff,
              onSelected: (val) {
                setState(() {
                  _isAuthorSameAsStaff = val;
                  if (val && _staffInvolved.isNotEmpty) {
                    _authorController.text = _staffInvolved.first;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Save Log Entry", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}