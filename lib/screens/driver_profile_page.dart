// lib/screens/driver_profile_page.dart

import 'package:flutter/material.dart';

import '../models/driver.dart';

class DriverProfilePage extends StatelessWidget {
  final Driver driver;

  const DriverProfilePage({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    int? driverNumber;
    String? nationality;

    // Try to read number & nationality safely, even if your Driver model
    // doesn't have them yet. This avoids crashes.
    try {
      final dynamic d = driver;

      final dynamic maybeNumber = d.number;
      if (maybeNumber is int) {
        driverNumber = maybeNumber;
      } else if (maybeNumber is String) {
        driverNumber = int.tryParse(maybeNumber);
      }

      final dynamic maybeNationality = d.nationality;
      if (maybeNationality is String && maybeNationality.isNotEmpty) {
        nationality = maybeNationality;
      }
    } catch (_) {
      // If the fields don't exist yet, we just leave them null.
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Number: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      driverNumber != null
                          ? driverNumber.toString()
                          : 'Not set',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Nationality: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      nationality ?? 'Not set',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Season stats',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Season statistics will appear here in a later version.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
