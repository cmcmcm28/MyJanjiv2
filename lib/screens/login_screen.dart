import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'verify_face_view.dart';
import 'dashboard_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentStep = 0; // 0: Upload IC, 1: Select User, 2: Face Scan, 3: Verified
  Uint8List? _icImage;
  User? _selectedUser; // User selected for login
  User? _verifiedUser;

  Future<void> _uploadIC() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Show dialog to choose source
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select IC Photo Source', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Camera', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _icImage = bytes;
          _currentStep = 1; // Move to user selection step
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectUser(User user) {
    setState(() {
      _selectedUser = user;
      _currentStep = 2; // Move to face scan step
    });
  }

  void _handleFaceVerification(bool success, Map<String, dynamic>? result) {
    if (success && result != null) {
      // Find user based on selected IC
      final user = UserService.findUserByIC(_selectedUser?.icNumber ?? '');
      
      if (user != null) {
        setState(() {
          _verifiedUser = user;
          _currentStep = 3; // Move to verified step
        });
        
        // Auto-navigate after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _navigateToDashboard(user);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User not found. Please try again.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['message'] ?? 'Face verification failed. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDashboard(User user) {
    UserService.currentUser = user;
    
    // Both users go to the same dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // Light blue to light purple gradient
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Image.asset(
                    'assets/images/myjanji_logov2.png',
                    width: 200,
                    fit: BoxFit.fitWidth,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MyJanji',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Main Content Card (White, Rounded, with Shadow)
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title with Purple Gradient (Centered)
                        ShaderMask(
                          shaderCallback: (bounds) => AppTheme.purpleGradient.createShader(bounds),
                          child: Text(
                            'Sign In to MyJanji',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Step Indicator
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepIndicator(0, 'Upload IC'),
                              Container(
                                width: 60,
                                height: 2,
                                color: _currentStep > 0
                                    ? AppTheme.primaryBlue
                                    : Colors.grey[300],
                              ),
                              _buildStepIndicator(1, 'Face Scan'),
                              Container(
                                width: 60,
                                height: 2,
                                color: _currentStep > 1
                                    ? AppTheme.primaryBlue
                                    : Colors.grey[300],
                              ),
                              _buildStepIndicator(2, 'Verified'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Step Content
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: _buildStepContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? AppTheme.primaryBlue
                    : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUploadICStep();
      case 1:
        return _buildSelectUserStep();
      case 2:
        return _buildFaceScanStep();
      case 3:
        return _buildVerifiedStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUploadICStep() {
    return Column(
      children: [
        const Icon(
          Icons.credit_card,
          size: 64,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: 20),
        Text(
          'Upload Your IC Photo',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please upload a clear photo of your MyKad for identity verification',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        if (_icImage != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _icImage!,
                fit: BoxFit.contain,
              ),
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No image selected',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _uploadIC,
          icon: const Icon(Icons.upload_file),
          label: Text(
            'Select IC Photo',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue, // Solid blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0, // Flat design
          ),
        ),
      ],
    );
  }

  Widget _buildSelectUserStep() {
    final availableUsers = UserService.getAllUsers();
    
    return Column(
      children: [
        const Icon(
          Icons.account_circle,
          size: 64,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: 20),
        Text(
          'Select Your Account',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the account you want to login as',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ...availableUsers.map((user) {
          final isSelected = _selectedUser?.id == user.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _selectUser(user),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IC: ${user.icNumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFaceScanStep() {
    return Column(
      children: [
        if (_selectedUser != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_rounded, size: 18, color: Colors.blue[900]),
                const SizedBox(width: 8),
                Text(
                  'Verifying as: ${_selectedUser!.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Position your face within the frame',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The system will automatically verify your identity',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Integrated Camera View
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: VerifyFaceView(
              onVerified: _handleFaceVerification,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedStep() {
    if (_verifiedUser == null) return const SizedBox.shrink();

    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        Text(
          'Identity Verified!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _verifiedUser!.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'IC: ${_verifiedUser!.icNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Redirecting to dashboard...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

