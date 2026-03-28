import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/transaction_model.dart';
import 'package:fixy_home_service/models/withdrawal_model.dart';
import 'package:intl/intl.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.provider != null) {
              await provider.loadProviderData(provider.provider!.userId);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (provider.withdrawalRequests.isNotEmpty) ...[
                _buildSectionHeader('Retiros Pendientes'),
                const SizedBox(height: 12),
                ...provider.withdrawalRequests
                    .where((w) =>
                        w.status == WithdrawalStatus.pending ||
                        w.status == WithdrawalStatus.processing)
                    .map((withdrawal) => _buildWithdrawalCard(withdrawal)),
              ],
              const SizedBox(height: 16),
              _buildSectionHeader('Historial de Transacciones'),
              const SizedBox(height: 12),
              if (provider.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay transacciones',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.transactions
                    .map((transaction) => _buildTransactionCard(transaction)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildWithdrawalCard(WithdrawalRequestModel withdrawal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: withdrawal.status == WithdrawalStatus.processing
              ? Colors.orange.shade200
              : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: withdrawal.status == WithdrawalStatus.processing
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: withdrawal.status == WithdrawalStatus.processing
                      ? Colors.orange
                      : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retiro ${withdrawal.statusLabel}',
                      style: AppTheme.textTheme.titleMedium
                          ?.copyWith(fontSize: 14),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy - HH:mm')
                          .format(withdrawal.requestedAt),
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${withdrawal.currency} ${withdrawal.amount.toStringAsFixed(2)}',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      withdrawal.bankName,
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.credit_card,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '****${withdrawal.bankAccountNumber.substring(withdrawal.bankAccountNumber.length - 4)}',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isPositive = transaction.type == TransactionType.earning ||
        transaction.type == TransactionType.refund;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: AppTheme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: AppTheme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm')
                      .format(transaction.createdAt),
                  style: AppTheme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.statusLabel,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(transaction.status),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.commission:
        return Icons.percent;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}
