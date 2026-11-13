import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Crea el checkout en el servidor (createMembershipCheckout) y lo abre
/// en el navegador. Lo usan el registro y la pantalla de inicio.
class MercadoPagoCheckoutService {
  // init_point usa www. y sandbox_init_point usa sandbox.
  static const _allowedHosts = {
    'www.mercadopago.com.mx',
    'sandbox.mercadopago.com.mx',
  };

  static HttpsCallable _callable(String name) =>
      FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(name);

  /// Lanza [FirebaseFunctionsException] si falla el servidor, o
  /// [Exception] si la URL no es válida o no se pudo abrir.
  static Future<void> open(int membershipPlanId) async {
    final membershipType = switch (membershipPlanId) {
      1 => 'day',
      2 => 'week',
      3 => 'month',
      _ => null,
    };

    if (membershipType == null) {
      throw Exception('Selecciona un plan válido para pagar en línea.');
    }

    final response = await _callable('createMembershipCheckout')
        .call<Map<String, dynamic>>({'membershipType': membershipType});

    await _launch(response.data['checkoutUrl'] as String?);
  }

  /// Abre Mercado Pago para que el alumno autorice el cobro automático
  /// de su plan (solo semana o mes). Lanza las mismas excepciones que [open].
  static Future<void> openSubscription(int membershipPlanId) async {
    final membershipType = switch (membershipPlanId) {
      2 => 'week',
      3 => 'month',
      _ => null,
    };

    if (membershipType == null) {
      throw Exception(
        'El cobro automático solo está disponible para semana y mes.',
      );
    }

    final response = await _callable('createMembershipSubscription')
        .call<Map<String, dynamic>>({'membershipType': membershipType});

    await _launch(response.data['checkoutUrl'] as String?);
  }

  /// Consulta en Mercado Pago el estado del cobro automático y lo guarda en
  /// Firestore (por si el aviso del webhook no llegó). Devuelve el estado.
  static Future<String?> syncSubscription() async {
    final response = await _callable(
      'syncMembershipSubscription',
    ).call<Map<String, dynamic>>();
    return response.data['status'] as String?;
  }

  /// Cancela el cobro automático. La membresía ya pagada sigue vigente.
  static Future<void> cancelSubscription() =>
      _callable('cancelMembershipSubscription').call<Map<String, dynamic>>();

  static Future<void> _launch(String? checkoutUrl) async {
    // El servidor decide si devuelve el checkout real o el sandbox
    // (MP_USE_SANDBOX en functions/.env).
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('Firebase no devolvió la URL de pago.');
    }

    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null ||
        uri.scheme != 'https' ||
        !_allowedHosts.contains(uri.host) ||
        uri.userInfo.isNotEmpty) {
      throw Exception('La URL de pago no es válida: $checkoutUrl');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      throw Exception('No se pudo abrir Mercado Pago.');
    }
  }
}
