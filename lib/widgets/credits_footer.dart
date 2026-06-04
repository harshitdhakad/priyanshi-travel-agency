import 'package:flutter/material.dart';
import '../services/app_theme.dart';

class CreditsFooter extends StatelessWidget {
  const CreditsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 12, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Director: Rajesh Kumar Dhakad  |  Dev: Harshit Dhakad',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
