
import 'package:flutter/material.dart';

class BuildLogoHeader extends StatelessWidget {
  final namecolor;
  const BuildLogoHeader({super.key, required this.namecolor});

  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4), // White border gap
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
            ],
            border: Border.all(color: Colors.green.shade100, width: 1)
          ),
          child: const CircleAvatar(
            radius: 20, // Adjust size here
            backgroundColor: Colors.white, 
            backgroundImage: AssetImage('assets/images/logo.png'), 
             
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "BUNSO ECO PARK",
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            color: namecolor, // Deep brand green
            letterSpacing: 1.2
          ),
        ),
      
      ],
    );
  }
}



 