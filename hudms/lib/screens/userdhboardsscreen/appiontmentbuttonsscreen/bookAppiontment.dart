import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hudms/screens/userdhboardsscreen/appiontmentbuttonsscreen/viewappointment.dart';

class StudentBookAppointmentScreen extends StatefulWidget {
  const StudentBookAppointmentScreen({super.key});

  @override
  State<StudentBookAppointmentScreen> createState() => _StudentBookAppointmentScreenState();
}

class _StudentBookAppointmentScreenState extends State<StudentBookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedDoctor;
  String? selectedTimeSlot;
  DateTime? selectedDate;
  bool isLoading = true;

  List<String> doctorNames = [];
  Map<String, String> doctorMap = {};
  String? studentEmail;
  String? studentName;
  late List<String> timeSlots;

  @override
  void initState() {
    super.initState();
    timeSlots = generate15MinSlots24Hours();
    fetchDoctors();
    fetchStudentInfo();
  }

  List<String> generate15MinSlots24Hours() {
    List<String> slots = [];
    TimeOfDay start = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 23, minute: 45);
    TimeOfDay current = start;
    while (true) {
      final next = addMinutes(current, 15);
      slots.add('${formatTime12(current)} - ${formatTime12(next)}');
      if (current.hour == end.hour && current.minute == end.minute) break;
      current = next;
    }
    return slots;
  }

  TimeOfDay addMinutes(TimeOfDay time, int minutes) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  String formatTime12(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      final names = <String>[];
      final map = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['name'] != null) {
          names.add(data['name']);
          map[data['name']] = doc.id;
        }
      }
      setState(() {
        doctorNames = names;
        doctorMap = map;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          final registration_number = doc.id;

          setState(() {
            studentEmail = user.email;
            studentName = data['name'] ?? 'Unnamed Student';
          });
        }
      } catch (e) {
        // silently fail or handle as needed
      }
    }
  }

  Future<List<String>> getBookedSlots(String doctorName, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorName', isEqualTo: doctorName)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .get();

    return snapshot.docs.map((doc) => doc['timeSlot'] as String).toList();
  }

  Future<void> saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (selectedDoctor == null || selectedDate == null || selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance.collection('appointments').add({
          'studentId': user.uid,
          'studentName': studentName ?? 'Unnamed Student',
          'studentEmail': studentEmail ?? 'N/A',
          'doctorName': selectedDoctor!,
          'doctorId': doctorMap[selectedDoctor!] ?? 'N/A',
          'date': Timestamp.fromDate(selectedDate!),
          'timeSlot': selectedTimeSlot!,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment')),
        );
      }
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            color: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => StudentViewAppointmentsScreen()));
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDoctor,
                  decoration: InputDecoration(
                    labelText: 'Select Doctor',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: doctorNames
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedDoctor = value),
                  validator: (value) => value == null ? 'Select a doctor' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => pickDate(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text(
                    selectedDate == null
                        ? 'Pick Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<String>>(
                  future: selectedDoctor != null && selectedDate != null
                      ? getBookedSlots(selectedDoctor!, selectedDate!)
                      : Future.value([]),
                  builder: (context, snapshot) {
                    final now = TimeOfDay.now();
                    final bookedSlots = snapshot.data ?? [];

                    return DropdownButtonFormField<String>(
                      value: selectedTimeSlot,
                      decoration: InputDecoration(
                        labelText: 'Select Time Slot',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: timeSlots.map((slot) {
                        final parts = slot.split(' - ')[0].split(':');
                        int hour = int.parse(parts[0]);
                        int minute = int.parse(parts[1].split(' ')[0]);
                        if (slot.contains('PM') && hour != 12) hour += 12;
                        if (slot.contains('AM') && hour == 12) hour = 0;
                        final slotStart = TimeOfDay(hour: hour, minute: minute);

                        final isToday = selectedDate != null &&
                            selectedDate!.day == DateTime.now().day &&
                            selectedDate!.month == DateTime.now().month &&
                            selectedDate!.year == DateTime.now().year;

                        final isPast = isToday &&
                            (slotStart.hour < now.hour ||
                                (slotStart.hour == now.hour && slotStart.minute <= now.minute));
                        final isBooked = bookedSlots.contains(slot);

                        return DropdownMenuItem(
                          value: isPast || isBooked ? null : slot,
                          enabled: !isPast && !isBooked,
                          child: Text(
                            isBooked
                                ? '$slot (Booked)'
                                : isPast
                                ? '$slot (Passed)'
                                : slot,
                            style: TextStyle(
                                color: isPast || isBooked ? Colors.grey : Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedTimeSlot = value),
                      validator: (value) => value == null ? 'Select a valid time slot' : null,
                    );
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: saveAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
