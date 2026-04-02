import 'package:flutter/material.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProvidersTab extends StatefulWidget {
  const ProvidersTab({Key? key}) : super(key: key);

  @override
  State<ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<ProvidersTab> {
  final ServiceRepository _repository = ServiceRepository();
  List<ProviderModel> _providers = [];
  bool _isLoading = true;
  String? _error;
  ProviderStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providers = await _repository.getProviders(status: _selectedFilter);
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar proveedores: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProviderStatus(
      ProviderModel provider, ProviderStatus newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus == ProviderStatus.active ? 'Aprobar Proveedor' : 'Rechazar Proveedor',
        ),
        content: Text(
          '¿Estás seguro de que deseas ${newStatus == ProviderStatus.active ? 'aprobar' : 'rechazar'} a ${provider.businessName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == ProviderStatus.active ? Colors.green : Colors.red,
            ),
            child: Text(newStatus == ProviderStatus.active ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final success = await _repository.updateProviderStatus(provider.id, newStatus);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Proveedor ${newStatus == ProviderStatus.active ? 'aprobado' : 'rechazado'} exitosamente',
            ),
            backgroundColor: newStatus == ProviderStatus.active ? Colors.green : Colors.orange,
          ),
        );
        await _loadProviders();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el estado del proveedor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProviderDetails(ProviderModel provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.businessName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', provider.email),
              _buildDetailRow('Teléfono', provider.phone),
              _buildDetailRow('Dirección', provider.address),
              _buildDetailRow('Ciudad', provider.city),
              _buildDetailRow('Experiencia', '${provider.yearsOfExperience} años'),
              _buildDetailRow('Categorías', provider.serviceCategories.join(', ')),
              if (provider.certifications.isNotEmpty)
                _buildDetailRow('Certificaciones', provider.certifications.join(', ')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(provider.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(provider.status),
                  style: TextStyle(
                    color: _getStatusColor(provider.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (provider.status == ProviderStatus.pending)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _updateProviderStatus(provider, ProviderStatus.active);
              },
              icon: const Icon(Icons.check),
              label: const Text('Aprobar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.pending:
        return Colors.orange;
      case ProviderStatus.active:
        return Colors.green;
      case ProviderStatus.inactive:
        return Colors.red;
      case ProviderStatus.suspended:
        return Colors.grey;
    }
  }

  String _getStatusText(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.pending:
        return 'Pendiente';
      case ProviderStatus.active:
        return 'Activo';
      case ProviderStatus.inactive:
        return 'Inactivo';
      case ProviderStatus.suspended:
        return 'Suspendido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProviders,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con filtros
              Row(
                children: [
                  Text(
                    'Gestión de Proveedores',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Filtro de status
                  DropdownButton<ProviderStatus?>(
                    value: _selectedFilter,
                    hint: const Text('Todos'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...ProviderStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFilter = value);
                      _loadProviders();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_providers.length} proveedores ${_selectedFilter != null ? '(${_getStatusText(_selectedFilter!)})' : ''}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              // Lista de proveedores
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 48, color: Colors.red.shade300),
                                const SizedBox(height: 16),
                                Text(_error!),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadProviders,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _providers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay proveedores ${_selectedFilter != null ? 'con este filtro' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _providers.length,
                                itemBuilder: (context, index) {
                                  final provider = _providers[index];
                                  return _buildProviderCard(provider);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showProviderDetails(provider),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: provider.profileImageUrl != null
                    ? Image.network(
                        provider.profileImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                      )
                    : _buildPlaceholderAvatar(),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.yearsOfExperience} años de experiencia • ${provider.serviceCategories.length} categorías',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge y acciones
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(provider.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(provider.status),
                      style: TextStyle(
                        color: _getStatusColor(provider.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botones de acción
                  if (provider.status == ProviderStatus.pending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _updateProviderStatus(
                              provider, ProviderStatus.active),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 28),
                          tooltip: 'Aprobar',
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        IconButton(
                          onPressed: () => _updateProviderStatus(
                              provider, ProviderStatus.inactive),
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 28),
                          tooltip: 'Rechazar',
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    )
                  else if (provider.status == ProviderStatus.active)
                    IconButton(
                      onPressed: () => _updateProviderStatus(
                          provider, ProviderStatus.inactive),
                      icon: const Icon(Icons.pause_circle,
                          color: Colors.orange, size: 28),
                      tooltip: 'Desactivar',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    )
                  else
                    IconButton(
                      onPressed: () => _updateProviderStatus(
                          provider, ProviderStatus.active),
                      icon: const Icon(Icons.play_circle,
                          color: Colors.green, size: 28),
                      tooltip: 'Activar',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        Icons.person,
        color: Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}
