import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/staff.dart'; // Assuming a Staff model exists
import '../../services/staff_service.dart'; // Assuming a StaffService exists

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Staff? _selectedStaff;

  @override
  Widget build(BuildContext context) {
    final staffListAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Clock-In / Clock-Out'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Staff Selection Dropdown
            staffListAsync.when(
              data: (staffList) => DropdownButtonFormField<Staff>(
                value: _selectedStaff,
                hint: const Text('Select Staff Member'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: staffList.map((staff) {
                  return DropdownMenuItem<Staff>(
                    value: staff,
                    child: Text(staff.name),
                  );
                }).toList(),
                onChanged: (Staff? newStaff) {
                  setState(() {
                    _selectedStaff = newStaff;
                  });
                },
                validator: (value) => value == null ? 'Please select a staff member' : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading staff: $err')),
            ),
            const SizedBox(height: 20),

            // TODO: Implement a PIN pad for verification in a real scenario

            const Spacer(),

            // Clock-In and Clock-Out Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStaff != null ? _clockIn : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Clock In'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStaff != null ? _clockOut : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clock Out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TODO: Display recent attendance logs for the selected staff
          ],
        ),
      ),
    );
  }

  void _clockIn() {
    if (_selectedStaff == null) return;
    // TODO: Implement clock-in logic
    // e.g., call a service to record the timestamp for the selected staff
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedStaff!.name} clocked in at ${DateTime.now()}')),
    );
  }

  void _clockOut() {
    if (_selectedStaff == null) return;
    // TODO: Implement clock-out logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedStaff!.name} clocked out at ${DateTime.now()}')),
    );
  }
}
