import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';

class MemberForm extends StatefulWidget {
  final bool showZoneDropdown;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final String zoneId;
  final String orgId;
  
  const MemberForm({
    Key? key, 
    this.showZoneDropdown = true,
    required this.onSubmit,
    this.initialData,
    required this.zoneId,
    required this.orgId,
  }) : super(key: key);

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();
  String? selectedZone;
  String? selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> zones = ['Zone A', 'Zone B', 'Zone C']; // Replace with actual zones
  final List<String> roles = ['ZONE-LEADER', 'ZONE-MEMBER', 'VIEWER'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      selectedZone = widget.initialData!['zone'];
      selectedRole = widget.initialData!['role'];
      _nameController.text = widget.initialData!['name'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _passwordController.text = widget.initialData!['password'] ?? '';
      _designationController.text = widget.initialData!['designation'] ?? '';
      _phoneController.text = widget.initialData!['phoneNumber'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
      key: _formKey,
      child: Column(
            mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
            ),
              const SizedBox(height: 20),
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
          ),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
            controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

              // Email
              TextFormField(
            controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

              // Password
              TextFormField(
            controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
            obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
          ),
          const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
          const SizedBox(height: 16),

              // Designation
              TextFormField(
            controller: _designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.assignment_ind),
                ),
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 24),

              // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedImage != null) {
                      widget.onSubmit({
                        'fullName': _nameController.text,
                        'email': _emailController.text,
                        'password': _passwordController.text,
                        'phoneNumber': _phoneController.text,
                        'designation': _designationController.text,
                        'role': selectedRole,
                        'signupType': 'LOCAL',
                        'file': _selectedImage,
                      });
                    } else if (_selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a profile image'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                    'Add Member',
                style: TextStyle(
                      color: AppColors.secondaryLight,
                  fontSize: 16,
                      fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
              const SizedBox(height: 20),
                    ],
                  ),
          ),
        ),
    );
  }
} 