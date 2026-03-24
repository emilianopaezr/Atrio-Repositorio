import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final secondaryColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Política de Privacidad',
          style: AtrioTypography.headingSmall.copyWith(color: textColor),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad',
              style: AtrioTypography.headingLarge.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: 1 de marzo de 2026',
              style: AtrioTypography.bodySmall.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 24),

            _SectionTitle('1. Información que Recopilamos', isDark),
            _SectionBody(
              'En Atrio recopilamos diferentes tipos de información para proporcionar y mejorar nuestros servicios:\n\n• Información de registro: nombre, correo electrónico, número de teléfono y foto de perfil.\n\n• Información de verificación: documentos de identidad para la verificación de anfitriones (KYC).\n\n• Datos de uso: interacciones con la aplicación, búsquedas, reservas, mensajes enviados y preferencias.\n\n• Información de dispositivo: modelo, sistema operativo, identificadores únicos y datos de red.\n\n• Datos de ubicación: con su consentimiento, para mostrar resultados relevantes cerca de usted.',
              isDark,
            ),

            _SectionTitle('2. Uso de la Información', isDark),
            _SectionBody(
              'Utilizamos su información personal para:\n\n• Facilitar la creación y gestión de su cuenta\n• Procesar reservas y transacciones de pago\n• Conectar usuarios con anfitriones de manera eficiente\n• Enviar notificaciones relevantes sobre reservas y mensajes\n• Mejorar y personalizar su experiencia en la plataforma\n• Prevenir fraudes y garantizar la seguridad de la comunidad\n• Cumplir con obligaciones legales y regulatorias\n• Generar análisis estadísticos anónimos para mejorar el servicio',
              isDark,
            ),

            _SectionTitle('3. Compartir Información', isDark),
            _SectionBody(
              'Atrio no vende su información personal a terceros. Podemos compartir información limitada en los siguientes casos:\n\n• Con otros usuarios: cuando realiza o recibe una reserva, compartimos la información necesaria para completar la transacción (nombre, foto, datos de contacto).\n\n• Proveedores de servicios: procesadores de pago, servicios de almacenamiento en la nube y herramientas de análisis que nos ayudan a operar la plataforma.\n\n• Requisitos legales: cuando sea necesario para cumplir con la ley, procesos legales o solicitudes gubernamentales.',
              isDark,
            ),

            _SectionTitle('4. Almacenamiento y Seguridad', isDark),
            _SectionBody(
              'Su información se almacena en servidores seguros con cifrado de extremo a extremo. Implementamos medidas de seguridad técnicas y organizativas para proteger sus datos contra acceso no autorizado, alteración, divulgación o destrucción. Los datos de pago se procesan a través de proveedores certificados PCI DSS y nunca se almacenan en nuestros servidores.',
              isDark,
            ),

            _SectionTitle('5. Retención de Datos', isDark),
            _SectionBody(
              'Conservamos su información personal mientras su cuenta esté activa o según sea necesario para proporcionarle servicios. Si solicita la eliminación de su cuenta, eliminaremos o anonimizaremos su información personal dentro de los 30 días siguientes, excepto cuando estemos obligados por ley a retener ciertos datos por un período específico.',
              isDark,
            ),

            _SectionTitle('6. Sus Derechos', isDark),
            _SectionBody(
              'Usted tiene derecho a:\n\n• Acceder a sus datos personales almacenados en nuestra plataforma\n• Rectificar información inexacta o desactualizada\n• Solicitar la eliminación de sus datos personales\n• Oponerse al procesamiento de sus datos para fines específicos\n• Solicitar la portabilidad de sus datos en formato estructurado\n• Retirar su consentimiento en cualquier momento\n\nPara ejercer estos derechos, contáctenos a través de privacy@atrio.app',
              isDark,
            ),

            _SectionTitle('7. Cookies y Tecnologías Similares', isDark),
            _SectionBody(
              'Utilizamos cookies y tecnologías similares para mejorar su experiencia, recordar sus preferencias y analizar el uso de la plataforma. Puede configurar su dispositivo para rechazar cookies, aunque esto podría afectar ciertas funcionalidades de la aplicación.',
              isDark,
            ),

            _SectionTitle('8. Menores de Edad', isDark),
            _SectionBody(
              'Atrio no está dirigido a menores de 18 años. No recopilamos conscientemente información personal de menores de edad. Si descubrimos que hemos recopilado información de un menor, tomaremos medidas para eliminar dicha información de nuestros registros.',
              isDark,
            ),

            _SectionTitle('9. Cambios en esta Política', isDark),
            _SectionBody(
              'Podemos actualizar esta política de privacidad periódicamente para reflejar cambios en nuestras prácticas de información. Le notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico. Le recomendamos revisar esta política regularmente.',
              isDark,
            ),

            _SectionTitle('10. Contacto', isDark),
            _SectionBody(
              'Si tiene preguntas sobre esta política de privacidad o sobre cómo manejamos su información personal, puede contactarnos:\n\n• Email: privacy@atrio.app\n• Centro de Ayuda dentro de la aplicación\n• Responsable de Protección de Datos: dpo@atrio.app',
              isDark,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: AtrioTypography.headingSmall.copyWith(
          color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionBody(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AtrioTypography.bodyMedium.copyWith(
        color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
        height: 1.7,
      ),
    );
  }
}
