import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/profile_models.dart';

class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  PaymentMethodType _selectedType = PaymentMethodType.creditCard;
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _appNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _appNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Añadir Método de Pago',
                style: AppTheme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Payment method type selector
              Text(
                'Tipo de método de pago',
                style: AppTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildPaymentTypeSelector(),
              const SizedBox(height: 24),

              // Form fields based on selected type
              ..._buildFormFields(),

              // Set as default checkbox
              CheckboxListTile(
                title: const Text('Establecer como método predeterminado'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePaymentMethod,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Guardar Método de Pago'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Row(
      children: [
        _buildPaymentTypeOption(
          PaymentMethodType.creditCard,
          'Tarjeta de Crédito',
          Icons.credit_card,
        ),
        const SizedBox(width: 8),
        _buildPaymentTypeOption(
          PaymentMethodType.debitCard,
          'Tarjeta de Débito',
          Icons.credit_card,
        ),
        const SizedBox(width: 8),
        _buildPaymentTypeOption(
          PaymentMethodType.paymentApp,
          'App de Pago',
          Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildPaymentTypeOption(
      PaymentMethodType type, String label, IconData icon) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    if (_selectedType == PaymentMethodType.creditCard ||
        _selectedType == PaymentMethodType.debitCard) {
      return [
        _buildTextField(
          'Número de tarjeta',
          _cardNumberController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el número de tarjeta';
            }
            return null;
          },
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Nombre del titular',
          _cardHolderController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el nombre del titular';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Fecha de vencimiento (MM/YY)',
                _expiryDateController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la fecha';
                  }
                  return null;
                },
                keyboardType: TextInputType.datetime,
                inputFormatters: [ExpiryDateInputFormatter()],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'CVV',
                _cvvController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el CVV';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
              ),
            ),
          ],
        ),
      ];
    } else {
      return [
        _buildTextField(
          'Nombre de la app (Yape, Plin, etc.)',
          _appNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el nombre de la app';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Número de cuenta o usuario',
          _accountNumberController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el número de cuenta o usuario';
            }
            return null;
          },
        ),
      ];
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        counterText: '', // Hide character counter
      ),
    );
  }

  void _savePaymentMethod() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final String id = DateTime.now().millisecondsSinceEpoch.toString();

      PaymentMethod newMethod;

      if (_selectedType == PaymentMethodType.creditCard ||
          _selectedType == PaymentMethodType.debitCard) {
        newMethod = PaymentMethod(
          id: id,
          type: _selectedType,
          cardNumber:
              '**** **** **** ${_cardNumberController.text.substring(max(0, _cardNumberController.text.length - 4))}',
          cardHolderName: _cardHolderController.text,
          expiryDate: _expiryDateController.text,
          isDefault: _isDefault,
        );
      } else {
        newMethod = PaymentMethod(
          id: id,
          type: _selectedType,
          appName: _appNameController.text,
          accountNumber: _accountNumberController.text,
          isDefault: _isDefault,
        );
      }

      provider.addPaymentMethod(newMethod);
      Navigator.pop(context);
    }
  }

  int max(int a, int b) {
    return a > b ? a : b;
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    String formatted = text.replaceAll('/', '');
    if (formatted.length > 4) {
      formatted = formatted.substring(0, 4);
    }

    if (formatted.length > 2) {
      formatted = '${formatted.substring(0, 2)}/${formatted.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
