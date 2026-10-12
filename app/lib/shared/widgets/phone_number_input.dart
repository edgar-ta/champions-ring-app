import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// País disponible para el selector del teléfono.
class PhoneCountryCode {
  final String country;
  final String dialCode;

  const PhoneCountryCode({required this.country, required this.dialCode});
}

/// Teléfono internacional con código de país seleccionable.
///
/// El valor emitido concatena el prefijo y los diez dígitos, por ejemplo
/// `+525512345678`. Para añadir países, agrega opciones a [countries].
class PhoneNumberInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? initialValue;

  const PhoneNumberInput({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  static const countries = <PhoneCountryCode>[
    PhoneCountryCode(country: 'MX', dialCode: '+52'),
    PhoneCountryCode(country: 'US/CA', dialCode: '+1'),
  ];

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  final _controller = TextEditingController();
  late PhoneCountryCode _country;

  @override
  void initState() {
    super.initState();
    _country = PhoneNumberInput.countries.first;
    final initial = widget.initialValue;
    if (initial != null) {
      for (final country in PhoneNumberInput.countries) {
        if (initial.startsWith(country.dialCode)) {
          _country = country;
          _controller.text = initial.substring(country.dialCode.length);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _fullValue => '${_country.dialCode}${_controller.text}';

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: widget.initialValue,
    validator: (value) {
      if (value == null || value == _country.dialCode) {
        return 'Campo requerido';
      }
      final nationalNumber = value.substring(_country.dialCode.length);
      if (nationalNumber.length != 10) return 'Debe tener 10 dígitos';
      return null;
    },
    builder: (field) => InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEA3A3F)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        errorText: field.errorText,
      ),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<PhoneCountryCode>(
              value: _country,
              isDense: true,
              selectedItemBuilder: (context) => PhoneNumberInput.countries
                  .map(
                    (country) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(country.dialCode),
                    ),
                  )
                  .toList(),
              items: PhoneNumberInput.countries
                  .map(
                    (country) => DropdownMenuItem(
                      value: country,
                      child: Text('${country.country} (${country.dialCode})'),
                    ),
                  )
                  .toList(),
              onChanged: (country) {
                if (country == null) return;
                setState(() => _country = country);
                field.didChange(_fullValue);
                widget.onChanged(_fullValue);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: 'Número de teléfono',
                border: InputBorder.none,
                isDense: true,
                counterText: '',
              ),
              onChanged: (_) {
                field.didChange(_fullValue);
                widget.onChanged(_fullValue);
              },
            ),
          ),
        ],
      ),
    ),
  );
}
