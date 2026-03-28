import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/screens/profile/widgets/profile_info_form.dart';

class ProfileInfoTab extends StatefulWidget {
  const ProfileInfoTab({Key? key}) : super(key: key);

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  bool _isEditing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.userProfile == null) {
          return const Center(child: Text('No profile data available'));
        }

        // Initialize controllers with user data if not editing yet
        if (!_isEditing) {
          final user = profileProvider.userProfile!;
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phone;
          _addressController.text = user.address;
          _cityController.text = user.city;
          _postalCodeController.text = user.postalCode;
        }

        return Container(
          color: AppTheme.backgroundColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile header with gradient background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Profile image (read-only, change from settings)
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(65),
                            child: profileProvider.profileImageBytes != null
                                ? Image.memory(
                                    profileProvider.profileImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    profileProvider.userProfile!.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileProvider.userProfile!.name,
                          style: AppTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileProvider.userProfile!.email,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Content area
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Información Personal',
                                  style:
                                      AppTheme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            _buildEditButton(),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Profile form
                        ProfileInfoForm(
                          formKey: _formKey,
                          nameController: _nameController,
                          emailController: _emailController,
                          phoneController: _phoneController,
                          addressController: _addressController,
                          cityController: _cityController,
                          postalCodeController: _postalCodeController,
                          isEditing: _isEditing,
                          onSave: _saveProfileInfo,
                          onCancel: _cancelEditing,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditButton() {
    if (_isEditing) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        color: AppTheme.primaryColor,
        onPressed: () {
          setState(() {
            _isEditing = true;
          });
        },
        tooltip: 'Editar información',
      ),
    );
  }

  void _saveProfileInfo() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.updateUserProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
      );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado exitosamente')),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      // Reset the form to original values
      final user =
          Provider.of<ProfileProvider>(context, listen: false).userProfile!;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _addressController.text = user.address;
      _cityController.text = user.city;
      _postalCodeController.text = user.postalCode;

      _isEditing = false;
    });
  }
}
