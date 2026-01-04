import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'manage_data_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 42),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo NB
                    Image.asset(
                      'assets/images/nb-logo.png',
                      height: 120, // Sesuaikan tinggi sesuai kebutuhan
                    ),
              const SizedBox(height: 6),
                    
                    const Text(
                      "UNI SCANNER",
                      style: TextStyle(
                        fontSize: 16, // Ukuran font diperbesar
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 73),


              // SCAN BUTTON
              DashboardButton(
                title: "SCAN",
                subtitle: "Scan Data",
                icon: Icons.qr_code_scanner,
                color: const Color(0xFF3A3A3A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerPage()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // MANAGE DATA BUTTON
              DashboardButton(
                title: "MANAGE DATA",
                subtitle: "Upload & Edit Data",
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF8D8D8D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageDataPage()),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
