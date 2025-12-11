import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dashboard_screen.dart';

class SecurityGatewayScreen extends StatefulWidget {
  const SecurityGatewayScreen({super.key});

  @override
  State<SecurityGatewayScreen> createState() => _SecurityGatewayScreenState();
}

class _SecurityGatewayScreenState extends State<SecurityGatewayScreen>
    with SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Logo
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Center(
                  child: Image.asset(
                    'assets/images/myjanji_logov2.png',
                    width: 250,
                    fit: BoxFit.fitWidth,
                    filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Welcome Text
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Welcome to MyJanji,\nyour trusted Promise Proofer',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Pulsing Circle
              if (!_isVerifying)
                FadeIn(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 200 + (_pulseController.value * 20),
                          height: 200 + (_pulseController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(
                                    0.1 - (_pulseController.value * 0.05)),
                          ),
                          child: Center(
                            child: Text(
                              'Tap MyKad\nto Verify Identity',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Verifying...',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

