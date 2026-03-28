import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/profile_models.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({Key? key}) : super(key: key);

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.userProfile == null) {
          return const Center(child: Text('No profile data available'));
        }

        final user = profileProvider.userProfile!;
        final rewards = profileProvider.rewards;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Points and referral summary
              _buildPointsSummary(user),

              const SizedBox(height: 24),

              // Referral program
              _buildReferralProgram(user),

              const SizedBox(height: 24),

              // Available rewards
              Text(
                'Recompensas Disponibles',
                style: AppTheme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Rewards grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  return _buildRewardCard(
                    rewards[index],
                    user.rewardPoints,
                    () => _redeemReward(profileProvider, rewards[index]),
                  );
                },
              ),

              const SizedBox(height: 24),

              // How to earn points section
              _buildHowToEarnPointsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsSummary(UserProfile user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus Puntos',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.rewardPoints}',
                    style: AppTheme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: user.rewardPoints / 1000, // Assume 1000 is the goal
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel Actual: ${_getUserLevel(user.rewardPoints)}',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                '${1000 - (user.rewardPoints % 1000)} puntos para el siguiente nivel',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUserLevel(int points) {
    if (points < 500) return 'Bronce';
    if (points < 1000) return 'Plata';
    if (points < 2000) return 'Oro';
    if (points < 5000) return 'Platino';
    return 'Diamante';
  }

  Widget _buildReferralProgram(UserProfile user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Programa de Referidos',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showReferralInfo(),
                tooltip: 'Más información',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comparte tu código con amigos y ambos ganarán S/25 en créditos cuando realicen su primer servicio.',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.referralCode,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.primaryColor),
                  onPressed: () => _copyReferralCode(user.referralCode),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareReferralCode(user.referralCode),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
      Reward reward, int userPoints, VoidCallback onRedeem) {
    final bool canRedeem =
        userPoints >= reward.pointsCost && !reward.isRedeemed;
    final bool isExpired = reward.expiryDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reward image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                Image.network(
                  reward.imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 40, color: Colors.grey),
                  ),
                ),
                if (reward.isRedeemed)
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Text(
                        'CANJEADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                if (isExpired && !reward.isRedeemed)
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Text(
                        'EXPIRADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.pointsCost}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reward details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: AppTheme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (canRedeem && !isExpired) ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(double.infinity, 36),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(reward.isRedeemed ? 'Canjeado' : 'Canjear'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnPointsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cómo Ganar Puntos',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnPointsItem(
            'Contrata servicios',
            'Gana 10 puntos por cada S/10 gastados',
            Icons.home_repair_service,
            Colors.blue,
          ),
          _buildEarnPointsItem(
            'Invita amigos',
            'Gana 100 puntos por cada amigo que se registre',
            Icons.person_add,
            Colors.green,
          ),
          _buildEarnPointsItem(
            'Valora servicios',
            'Gana 25 puntos por cada reseña',
            Icons.star,
            Colors.amber,
          ),
          _buildEarnPointsItem(
            'Completa tu perfil',
            'Gana 50 puntos por completar tu perfil',
            Icons.person,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildEarnPointsItem(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  void _shareReferralCode(String code) {
    // In a real app, this would open a share sheet
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compartiendo código: $code')),
    );
  }

  void _showReferralInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programa de Referidos'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cómo funciona:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Comparte tu código de referido con amigos que aún no usen la app.',
              ),
              SizedBox(height: 4),
              Text(
                '2. Cuando tu amigo se registre y use tu código, ambos recibirán S/25 en créditos.',
              ),
              SizedBox(height: 4),
              Text(
                '3. Los créditos se activarán cuando tu amigo complete su primer servicio.',
              ),
              SizedBox(height: 16),
              Text(
                'Téórminos y condiciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '- El valor del crédito puede variar según promociones.',
              ),
              SizedBox(height: 4),
              Text(
                '- Los créditos expiran 3 meses después de ser otorgados.',
              ),
              SizedBox(height: 4),
              Text(
                '- No hay límite en el número de referidos.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _redeemReward(ProfileProvider provider, Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canjear Recompensa'),
        content: Text(
          '¿Estás seguro de que deseas canjear "${reward.title}" por ${reward.pointsCost} puntos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.redeemReward(reward.id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Recompensa canjeada exitosamente!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }
}
