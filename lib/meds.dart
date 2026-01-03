import 'package:flutter/material.dart';
import 'api_service.dart';

class Med {
  final String mid;
  final String name;
  final String dose;
  final TimeOfDay time;
  bool taken;

  Med({
    required this.mid,
    required this.name,
    required this.dose,
    required this.time,
    required this.taken,
  });

  factory Med.fromJson(Map<String, dynamic> json) {
    final parts = json['time'].toString().split(':');
    return Med(
      mid: json['mid'].toString(),
      name: json['name'],
      dose: json['dose'],
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      taken: json['taken'] == 1,
    );
  }
}

class MedsPage extends StatefulWidget {
  final String uid;
  const MedsPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  List<Med> meds = [];

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    final data = await ApiService.getMedications(widget.uid);
    setState(() {
      meds = data.map<Med>((e) => Med.fromJson(e)).toList();
    });
  }

  // -------- ADD MED --------
  Future<void> _addMed() async {
    String name = '';
    String dose = '';
    TimeOfDay time = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Medication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Dose'),
                onChanged: (v) => dose = v,
              ),
              TextButton(
                child: Text(time.format(context)),
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (t != null) setStateDialog(() => time = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;

                final success = await ApiService.addMedication(
                  uid: widget.uid,
                  name: name,
                  dose: dose.isEmpty ? "1 dose" : dose,
                  time:
                      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                );

                if (success) {
                  Navigator.pop(context);
                  await _loadMeds();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Failed to save medication"),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------- DELETE MED --------
  Future<void> _deleteMed(Med m) async {
    await ApiService.deleteMedication(uid: widget.uid, mid: m.mid);
    await _loadMeds();
  }

  // -------- TOGGLE TAKEN --------
  Future<void> _toggleTaken(Med m, bool value) async {
    setState(() => m.taken = value);

    await ApiService.updateMedication(
      uid: widget.uid,
      mid: m.mid,
      taken: value ? 1 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: meds.isEmpty
          ? const Center(child: Text('No medications found'))
          : ListView.builder(
              itemCount: meds.length,
              itemBuilder: (_, i) {
                final m = meds[i];
                return Dismissible(
                  key: ValueKey(m.mid),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteMed(m),
                  child: ListTile(
                    leading: const Icon(Icons.medication),
                    title: Text(
                      m.name,
                      style: TextStyle(
                        decoration: m.taken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${m.dose} • ${m.time.format(context)}'),
                    trailing: Checkbox(
                      value: m.taken,
                      onChanged: (v) => _toggleTaken(m, v ?? false),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
