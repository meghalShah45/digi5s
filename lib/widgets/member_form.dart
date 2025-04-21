import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MemberForm extends StatefulWidget {
  final bool showZoneDropdown;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  
  const MemberForm({
    Key? key, 
    this.showZoneDropdown = true,
    required this.onSubmit,
    this.initialData,
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
  final TextEditingController _contactController = TextEditingController();
  String? _photoUrl;

  final List<String> zones = ['Zone A', 'Zone B', 'Zone C']; // Replace with actual zones
  final List<String> roles = ['Member', 'Leader', 'Viewer']; // Replace with actual roles

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
      _contactController.text = widget.initialData!['contact'] ?? '';
      _photoUrl = widget.initialData!['photo'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final memberData = {
        if (widget.showZoneDropdown) 'zone': selectedZone,
        'role': selectedRole,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'designation': _designationController.text,
        'contact': _contactController.text,
        'photo': _photoUrl,
      };
      widget.onSubmit(memberData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showZoneDropdown) ...[
            _buildDropdown(
              'Select Zone',
              zones,
              selectedZone,
              (value) => setState(() => selectedZone = value),
            ),
            const SizedBox(height: 16),
          ],
          _buildDropdown(
            'Select Role',
            roles,
            selectedRole,
            (value) => setState(() => selectedRole = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Contact Person Name',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter name' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email ID',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Please enter valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter password' : null,
          ),
          const SizedBox(height: 16),
          _buildPhotoUpload(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _designationController,
            label: 'Your Designation',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter designation' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contactController,
            label: 'Contact No',
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter contact number' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(label),
              items: items.map((String item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // Implement photo upload functionality
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
} 