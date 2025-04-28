import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/provider/theme_provider.dart';

class NavCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget destination;

  const NavCard({
    super.key,
    required this.title,
    required this.icon,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final Themeprovider themeProvider = Provider.of<Themeprovider>(
      context,
      listen: false,
    ); // Get the theme provider instance
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color:
          themeProvider.isDark
              ? const Color.fromARGB(255, 60, 80, 99)
              : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color:
                    themeProvider.isDark
                        ? Colors.white
                        : themeProvider.themeData.primaryColor,
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
