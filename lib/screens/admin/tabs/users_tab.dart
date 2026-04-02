import 'package:flutter/material.dart';
import 'package:fixy_home_service/services/admin_service.dart';

/// Pestaña de gestión de usuarios del admin
/// Permite ver usuarios y asignar/quitar permisos de administrador
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final AdminService _adminService = AdminService();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando usuarios: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final users = await _adminService.searchUsers(query);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error buscando usuarios: $e');
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool currentStatus) async {
    try {
      final success = await _adminService.setUserAdmin(userId, !currentStatus);
      if (success) {
        _showSuccess(currentStatus
            ? 'Permisos de admin removidos'
            : 'Usuario ahora es administrador');
        _loadUsers(); // Recargar lista
      } else {
        _showError('No se pudo actualizar los permisos');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por email o nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                _searchQuery = value;
                _searchUsers(value);
              },
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron usuarios',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isAdmin = user['is_admin'] == true;
                          final email = user['email'] ?? 'Sin email';
                          final userId = user['id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAdmin
                                    ? Colors.red[100]
                                    : Colors.blue[100],
                                child: Icon(
                                  isAdmin
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  color: isAdmin ? Colors.red : Colors.blue,
                                ),
                              ),
                              title: Text(email),
                              subtitle: isAdmin
                                  ? const Text('Administrador',
                                      style: TextStyle(color: Colors.red))
                                  : const Text('Usuario'),
                              trailing: Switch(
                                value: isAdmin,
                                onChanged: (value) {
                                  _toggleAdminStatus(userId, isAdmin);
                                },
                                activeThumbColor: Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
