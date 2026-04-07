import 'package:flutter/material.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProvidersTab extends StatefulWidget {
  const ProvidersTab({super.key});

  @override
  State<ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<ProvidersTab> {
  final ServiceRepository _repository = ServiceRepository();
  List<ProviderModel> _pendingProviders = [];
  List<ProviderModel> _activeProviders = [];
  bool _isLoading = true;
  String? _error;

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
      final pending = await _repository.getPendingProviders();
      final active = await _repository.getActiveProviders();
      setState(() {
        _pendingProviders = pending;
        _activeProviders = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar proveedores: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveProvider(ProviderModel provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Proveedor'),
        content: Text(
            '¿Aprobar a ${provider.businessName}? Se marcará como verificado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // Actualizar status a active e is_verified a true
        await SupabaseConfig.client.from('providers').update({
          'status': 'active',
          'is_verified': true,
        }).eq('id', provider.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.businessName} aprobado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProviders();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectProvider(ProviderModel provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Proveedor'),
        content: Text('¿Rechazar a ${provider.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // Actualizar status a rejected
        await SupabaseConfig.client
            .from('providers')
            .update({'status': 'rejected'}).eq('id', provider.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.businessName} rechazado'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadProviders();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProviders,
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
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección: Pendientes de Aprobación
                        if (_pendingProviders.isNotEmpty) ...[
                          Text(
                            'Pendientes de Aprobación (${_pendingProviders.length})',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._pendingProviders.map(
                              (p) => _buildProviderCard(p, isPending: true)),
                          const SizedBox(height: 24),
                        ],

                        // Sección: Proveedores Activos
                        Text(
                          'Proveedores Activos (${_activeProviders.length})',
                          style: AppTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_activeProviders.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay proveedores activos',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._activeProviders.map(
                              (p) => _buildProviderCard(p, isPending: false)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel provider, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Foto de perfil
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: provider.profileImageUrl != null
                  ? Image.network(
                      provider.profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                    )
                  : _buildPlaceholderAvatar(),
            ),
            const SizedBox(width: 16),
            // Información
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
                    provider.serviceCategories.join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.yearsOfExperience} años de experiencia • ${provider.phone}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Botones de acción (solo para pendientes)
            if (isPending)
              Column(
                children: [
                  IconButton(
                    onPressed: () => _approveProvider(provider),
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    tooltip: 'Aprobar',
                  ),
                  IconButton(
                    onPressed: () => _rejectProvider(provider),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                    tooltip: 'Rechazar',
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Activo',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 60,
      height: 60,
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
