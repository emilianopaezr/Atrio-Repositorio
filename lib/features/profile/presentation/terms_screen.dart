import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final secondaryColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
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
              'Términos y Condiciones de Uso',
              style: AtrioTypography.headingLarge.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: 1 de marzo de 2026',
              style: AtrioTypography.bodySmall.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 24),

            _SectionTitle('1. Aceptación de los Términos', isDark),
            _SectionBody(
              'Al acceder y utilizar la aplicación Atrio ("la Plataforma"), usted acepta estar vinculado por estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no podrá acceder ni utilizar nuestros servicios. Estos términos constituyen un acuerdo legalmente vinculante entre usted y Atrio Technologies SpA',
              isDark,
            ),

            _SectionTitle('2. Descripción del Servicio', isDark),
            _SectionBody(
              'Atrio es una plataforma de marketplace premium que conecta a anfitriones con usuarios, facilitando la reserva de espacios, experiencias y servicios profesionales. La Plataforma actúa como intermediario entre las partes, proporcionando las herramientas tecnológicas necesarias para que los usuarios publiquen, descubran y reserven ofertas.',
              isDark,
            ),

            _SectionTitle('3. Registro y Cuentas de Usuario', isDark),
            _SectionBody(
              'Para utilizar ciertos servicios de Atrio, debe crear una cuenta proporcionando información precisa y completa. Usted es responsable de mantener la confidencialidad de sus credenciales de acceso y de todas las actividades que ocurran bajo su cuenta. Debe notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta o cualquier violación de seguridad.',
              isDark,
            ),

            _SectionTitle('4. Roles de Usuario', isDark),
            _SectionBody(
              'Los usuarios pueden operar en dos modalidades dentro de Atrio:\n\n• Modo Usuario: Permite explorar, buscar y reservar espacios, experiencias y servicios publicados por los anfitriones.\n\n• Modo Anfitrión: Permite publicar y gestionar espacios, experiencias y servicios, recibir reservas y administrar ingresos a través del panel de control.',
              isDark,
            ),

            _SectionTitle('5. Reservas y Pagos', isDark),
            _SectionBody(
              'Todas las transacciones se procesan a través de nuestros proveedores de pago autorizados. Atrio cobra una comisión de servicio sobre cada transacción completada. Las tarifas, comisiones y cargos adicionales se mostrarán de forma transparente antes de confirmar cualquier reserva. Los anfitriones recibirán sus pagos según el calendario de desembolsos establecido.',
              isDark,
            ),

            _SectionTitle('6. Cancelaciones y Reembolsos', isDark),
            _SectionBody(
              'Las políticas de cancelación varían según el tipo de reserva y las condiciones establecidas por cada anfitrión. Los usuarios podrán cancelar reservas según la política aplicable. Los reembolsos se procesarán dentro de los 5-10 días hábiles siguientes a la aprobación de la cancelación, utilizando el mismo método de pago original.',
              isDark,
            ),

            _SectionTitle('7. Conducta del Usuario', isDark),
            _SectionBody(
              'Los usuarios se comprometen a:\n\n• No utilizar la plataforma para fines ilegales o no autorizados\n• No publicar contenido falso, engañoso o fraudulento\n• Respetar los derechos de propiedad intelectual de terceros\n• Mantener una conducta respetuosa en todas las interacciones\n• No intentar eludir las medidas de seguridad de la plataforma\n• No manipular reseñas o calificaciones',
              isDark,
            ),

            _SectionTitle('8. Propiedad Intelectual', isDark),
            _SectionBody(
              'Todo el contenido de Atrio, incluyendo pero no limitado a textos, gráficos, logotipos, iconos, imágenes, clips de audio, descargas digitales y compilaciones de datos, es propiedad de Atrio Technologies SpA o de sus proveedores de contenido y está protegido por las leyes de propiedad intelectual aplicables.',
              isDark,
            ),

            _SectionTitle('9. Limitación de Responsabilidad', isDark),
            _SectionBody(
              'Atrio actúa como intermediario y no es responsable de las acciones, conductas o contenidos de los usuarios. No garantizamos la calidad, seguridad o legalidad de los espacios, experiencias o servicios publicados. Los usuarios asumen toda responsabilidad por sus interacciones y transacciones realizadas a través de la plataforma.',
              isDark,
            ),

            _SectionTitle('10. Modificaciones', isDark),
            _SectionBody(
              'Atrio se reserva el derecho de modificar estos términos en cualquier momento. Las modificaciones entrarán en vigor a partir de su publicación en la plataforma. El uso continuado de la aplicación después de cualquier modificación constituye su aceptación de los nuevos términos.',
              isDark,
            ),

            _SectionTitle('11. Contacto', isDark),
            _SectionBody(
              'Para consultas sobre estos términos, puede contactarnos a través de:\n\n• Email: legal@atrio.app\n• Centro de Ayuda dentro de la aplicación\n• Dirección: Atrio Technologies SpA, Santiago de Chile, Chile',
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
