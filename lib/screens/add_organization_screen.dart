import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'active_organizations_screen.dart';

class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  bool isSubscription = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Organization'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      controller: _nameController,
                      label: 'Organization Name',
                      icon: Icons.business,
                      hint: 'Enter organization name',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _gstController,
                      label: 'GST Number',
                      icon: Icons.receipt_long,
                      hint: 'Enter GST number',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _panController,
                      label: 'PAN Number',
                      icon: Icons.credit_card,
                      hint: 'Enter PAN number',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      hint: 'Enter address',
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, color: AppColors.secondaryLight),
                        label: const Text('Add Organization', style: TextStyle(color: AppColors.secondaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: implement create organization logic
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.primary : AppColors.secondaryDark, width: 2),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? AppColors.secondaryLight : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: AppColors.secondaryDark,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: validator,
        ),
      ],
    );
  }
}