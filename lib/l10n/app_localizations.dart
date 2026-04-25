import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @sectionNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get sectionNotifications;

  /// No description provided for @sectionPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get sectionPrivacy;

  /// No description provided for @sectionGeneral.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get sectionAccount;

  /// No description provided for @notifBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas nuevas'**
  String get notifBookings;

  /// No description provided for @notifMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get notifMessages;

  /// No description provided for @notifReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get notifReminders;

  /// No description provided for @notifPromos.
  ///
  /// In es, this message translates to:
  /// **'Promociones'**
  String get notifPromos;

  /// No description provided for @notifUpdates.
  ///
  /// In es, this message translates to:
  /// **'Actualizaciones de la app'**
  String get notifUpdates;

  /// No description provided for @privacyVisible.
  ///
  /// In es, this message translates to:
  /// **'Perfil visible'**
  String get privacyVisible;

  /// No description provided for @privacyRatings.
  ///
  /// In es, this message translates to:
  /// **'Mostrar calificaciones'**
  String get privacyRatings;

  /// No description provided for @lblLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get lblLanguage;

  /// No description provided for @lblCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get lblCurrency;

  /// No description provided for @lblTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get lblTimezone;

  /// No description provided for @lblChangePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get lblChangePassword;

  /// No description provided for @lblDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get lblDeleteAccount;

  /// No description provided for @dlgCurrentPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get dlgCurrentPassword;

  /// No description provided for @dlgNewPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get dlgNewPassword;

  /// No description provided for @dlgDeleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es permanente. Se eliminarán todos tus datos, reservas y publicaciones. ¿Estás seguro?'**
  String get dlgDeleteAccountConfirm;

  /// No description provided for @btnCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get btnSave;

  /// No description provided for @btnDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get btnDelete;

  /// No description provided for @btnRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get btnRetry;

  /// No description provided for @btnContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get btnContinue;

  /// No description provided for @btnBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get btnBack;

  /// No description provided for @btnNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get btnNext;

  /// No description provided for @btnSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get btnSend;

  /// No description provided for @btnConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get btnConfirm;

  /// No description provided for @btnClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get btnClose;

  /// No description provided for @btnEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get btnEdit;

  /// No description provided for @btnShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get btnShare;

  /// No description provided for @btnExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get btnExplore;

  /// No description provided for @btnYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get btnYes;

  /// No description provided for @btnNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get btnNo;

  /// No description provided for @msgPasswordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get msgPasswordUpdated;

  /// No description provided for @msgDeleteRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de eliminación enviada'**
  String get msgDeleteRequested;

  /// No description provided for @langChooseTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige un idioma'**
  String get langChooseTitle;

  /// No description provided for @langSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @langEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get langEnglish;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get navBookings;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get navDashboard;

  /// No description provided for @navCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get navCalendar;

  /// No description provided for @navListings.
  ///
  /// In es, this message translates to:
  /// **'Listados'**
  String get navListings;

  /// No description provided for @navFinance.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get navFinance;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error'**
  String get commonError;

  /// No description provided for @commonUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta de nuevo.'**
  String get commonUnexpectedError;

  /// No description provided for @commonNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get commonNoResults;

  /// No description provided for @commonRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get commonRequired;

  /// No description provided for @monthAbbrJan.
  ///
  /// In es, this message translates to:
  /// **'Ene'**
  String get monthAbbrJan;

  /// No description provided for @monthAbbrFeb.
  ///
  /// In es, this message translates to:
  /// **'Feb'**
  String get monthAbbrFeb;

  /// No description provided for @monthAbbrMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get monthAbbrMar;

  /// No description provided for @monthAbbrApr.
  ///
  /// In es, this message translates to:
  /// **'Abr'**
  String get monthAbbrApr;

  /// No description provided for @monthAbbrMay.
  ///
  /// In es, this message translates to:
  /// **'May'**
  String get monthAbbrMay;

  /// No description provided for @monthAbbrJun.
  ///
  /// In es, this message translates to:
  /// **'Jun'**
  String get monthAbbrJun;

  /// No description provided for @monthAbbrJul.
  ///
  /// In es, this message translates to:
  /// **'Jul'**
  String get monthAbbrJul;

  /// No description provided for @monthAbbrAug.
  ///
  /// In es, this message translates to:
  /// **'Ago'**
  String get monthAbbrAug;

  /// No description provided for @monthAbbrSep.
  ///
  /// In es, this message translates to:
  /// **'Sep'**
  String get monthAbbrSep;

  /// No description provided for @monthAbbrOct.
  ///
  /// In es, this message translates to:
  /// **'Oct'**
  String get monthAbbrOct;

  /// No description provided for @monthAbbrNov.
  ///
  /// In es, this message translates to:
  /// **'Nov'**
  String get monthAbbrNov;

  /// No description provided for @monthAbbrDec.
  ///
  /// In es, this message translates to:
  /// **'Dic'**
  String get monthAbbrDec;

  /// No description provided for @authWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get authWelcome;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar en Atrio'**
  String get authLoginSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authConfirmPassword;

  /// No description provided for @authFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authFullName;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get authSignIn;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrContinueWith.
  ///
  /// In es, this message translates to:
  /// **'o continúa con'**
  String get authOrContinueWith;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get authNoAccount;

  /// No description provided for @authSignUp.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get authSignUp;

  /// No description provided for @authCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get authCreateAccount;

  /// No description provided for @authCreateAccountBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authCreateAccountBtn;

  /// No description provided for @authJoinAtrio.
  ///
  /// In es, this message translates to:
  /// **'Únete a '**
  String get authJoinAtrio;

  /// No description provided for @authStartToday.
  ///
  /// In es, this message translates to:
  /// **' y comienza hoy'**
  String get authStartToday;

  /// No description provided for @authAcceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Al registrarte aceptas nuestros '**
  String get authAcceptTerms;

  /// No description provided for @authTermsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos de Servicio'**
  String get authTermsOfService;

  /// No description provided for @authAnd.
  ///
  /// In es, this message translates to:
  /// **' y '**
  String get authAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get authPrivacyPolicy;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get authHaveAccount;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.'**
  String get authResetPasswordHint;

  /// No description provided for @authYourEmail.
  ///
  /// In es, this message translates to:
  /// **'Tu email'**
  String get authYourEmail;

  /// No description provided for @authResetSent.
  ///
  /// In es, this message translates to:
  /// **'Si el email está registrado, recibirás un enlace de recuperación.'**
  String get authResetSent;

  /// No description provided for @authResetEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu email para recuperar tu contraseña.'**
  String get authResetEnterEmail;

  /// No description provided for @authEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email no válido'**
  String get authInvalidEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get authEnterPassword;

  /// No description provided for @authCreatePassword.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una contraseña'**
  String get authCreatePassword;

  /// No description provided for @authMinChars.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get authMinChars;

  /// No description provided for @authIncludeUpper.
  ///
  /// In es, this message translates to:
  /// **'Incluye al menos una mayúscula'**
  String get authIncludeUpper;

  /// No description provided for @authIncludeNumber.
  ///
  /// In es, this message translates to:
  /// **'Incluye al menos un número'**
  String get authIncludeNumber;

  /// No description provided for @authConfirmPwd.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get authConfirmPwd;

  /// No description provided for @authPwdMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get authPwdMismatch;

  /// No description provided for @authEnterName.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get authEnterName;

  /// No description provided for @authNameMinChars.
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 2 caracteres'**
  String get authNameMinChars;

  /// No description provided for @authGoogleFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google. Intenta de nuevo.'**
  String get authGoogleFail;

  /// No description provided for @authGoogleFailRegister.
  ///
  /// In es, this message translates to:
  /// **'No se pudo continuar con Google. Intenta de nuevo.'**
  String get authGoogleFailRegister;

  /// No description provided for @authGoToLogin.
  ///
  /// In es, this message translates to:
  /// **'Ir a Login'**
  String get authGoToLogin;

  /// No description provided for @authAccountCreated.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Te enviamos un código de verificación.'**
  String get authAccountCreated;

  /// No description provided for @authAccountCreatedConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Revisa tu email para confirmar tu cuenta.'**
  String get authAccountCreatedConfirm;

  /// No description provided for @authStrengthWeak.
  ///
  /// In es, this message translates to:
  /// **'Débil'**
  String get authStrengthWeak;

  /// No description provided for @authStrengthRegular.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get authStrengthRegular;

  /// No description provided for @authStrengthGood.
  ///
  /// In es, this message translates to:
  /// **'Buena'**
  String get authStrengthGood;

  /// No description provided for @authStrengthStrong.
  ///
  /// In es, this message translates to:
  /// **'Fuerte'**
  String get authStrengthStrong;

  /// No description provided for @verifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a'**
  String get verifySubtitle;

  /// No description provided for @verifyButton.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get verifyButton;

  /// No description provided for @verifyResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get verifyResend;

  /// No description provided for @verifyResendCooldown.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código ({seconds} s)'**
  String verifyResendCooldown(int seconds);

  /// No description provided for @verifyExpire.
  ///
  /// In es, this message translates to:
  /// **'El código expira en 15 minutos'**
  String get verifyExpire;

  /// No description provided for @verifyEnterFullCode.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código completo de 6 dígitos.'**
  String get verifyEnterFullCode;

  /// No description provided for @verifyNoSession.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la sesión. Intenta iniciar sesión de nuevo.'**
  String get verifyNoSession;

  /// No description provided for @verifyEmailVerified.
  ///
  /// In es, this message translates to:
  /// **'Email verificado correctamente.'**
  String get verifyEmailVerified;

  /// No description provided for @verifyIncorrect.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto o expirado.'**
  String get verifyIncorrect;

  /// No description provided for @verifyErrorCheck.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar el código. Intenta de nuevo.'**
  String get verifyErrorCheck;

  /// No description provided for @verifyResent.
  ///
  /// In es, this message translates to:
  /// **'Código reenviado a tu email.'**
  String get verifyResent;

  /// No description provided for @verifySendFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el código. Intenta de nuevo.'**
  String get verifySendFail;

  /// No description provided for @homeSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar espacios, experiencias...'**
  String get homeSearchHint;

  /// No description provided for @homeQuickServicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios Rápidos'**
  String get homeQuickServicesTitle;

  /// No description provided for @homeQuickServicesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mudanza, limpieza, armado y más'**
  String get homeQuickServicesSubtitle;

  /// No description provided for @homeBecomeHostTitle.
  ///
  /// In es, this message translates to:
  /// **'Sé anfitrión en Atrio'**
  String get homeBecomeHostTitle;

  /// No description provided for @homeBecomeHostSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Publica tu espacio y genera ingresos'**
  String get homeBecomeHostSubtitle;

  /// No description provided for @homeBecomeHostCta.
  ///
  /// In es, this message translates to:
  /// **'Sé anfitrión'**
  String get homeBecomeHostCta;

  /// No description provided for @homeNoListings.
  ///
  /// In es, this message translates to:
  /// **'No hay anuncios disponibles'**
  String get homeNoListings;

  /// No description provided for @homeNoListingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Intenta con otra categoría o vuelve más tarde'**
  String get homeNoListingsSubtitle;

  /// No description provided for @homeLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar anuncios'**
  String get homeLoadError;

  /// No description provided for @homeUnitNight.
  ///
  /// In es, this message translates to:
  /// **'noche'**
  String get homeUnitNight;

  /// No description provided for @homeUnitHour.
  ///
  /// In es, this message translates to:
  /// **'hr'**
  String get homeUnitHour;

  /// No description provided for @homeUnitSession.
  ///
  /// In es, this message translates to:
  /// **'sesión'**
  String get homeUnitSession;

  /// No description provided for @homeUnitPerson.
  ///
  /// In es, this message translates to:
  /// **'persona'**
  String get homeUnitPerson;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Espacios, experiencias, servicios...'**
  String get searchHint;

  /// No description provided for @searchNearbyOn.
  ///
  /// In es, this message translates to:
  /// **'Cerca: {km} km'**
  String searchNearbyOn(int km);

  /// No description provided for @searchNearMe.
  ///
  /// In es, this message translates to:
  /// **'Cerca de mí'**
  String get searchNearMe;

  /// No description provided for @searchLocationFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo acceder a tu ubicación. Usando Santiago centro.'**
  String get searchLocationFailed;

  /// No description provided for @searchPriceRange.
  ///
  /// In es, this message translates to:
  /// **'Rango de Precio'**
  String get searchPriceRange;

  /// No description provided for @searchQuickFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros Rápidos'**
  String get searchQuickFilters;

  /// No description provided for @searchFilterSuperhost.
  ///
  /// In es, this message translates to:
  /// **'Superhost'**
  String get searchFilterSuperhost;

  /// No description provided for @searchFilterPool.
  ///
  /// In es, this message translates to:
  /// **'Piscina'**
  String get searchFilterPool;

  /// No description provided for @searchFilterKitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get searchFilterKitchen;

  /// No description provided for @searchPopular.
  ///
  /// In es, this message translates to:
  /// **'Búsquedas Populares'**
  String get searchPopular;

  /// No description provided for @searchPopularStudios.
  ///
  /// In es, this message translates to:
  /// **'Estudios Foto'**
  String get searchPopularStudios;

  /// No description provided for @searchPopularVillas.
  ///
  /// In es, this message translates to:
  /// **'Villas Premium'**
  String get searchPopularVillas;

  /// No description provided for @searchPopularLoft.
  ///
  /// In es, this message translates to:
  /// **'Loft Creativo'**
  String get searchPopularLoft;

  /// No description provided for @searchPopularExperiences.
  ///
  /// In es, this message translates to:
  /// **'Experiencias'**
  String get searchPopularExperiences;

  /// No description provided for @searchBrowseByCategory.
  ///
  /// In es, this message translates to:
  /// **'Explorar por Categoría'**
  String get searchBrowseByCategory;

  /// No description provided for @searchCategorySpaces.
  ///
  /// In es, this message translates to:
  /// **'Espacios'**
  String get searchCategorySpaces;

  /// No description provided for @searchCategorySpacesDesc.
  ///
  /// In es, this message translates to:
  /// **'Studios, lofts, villas'**
  String get searchCategorySpacesDesc;

  /// No description provided for @searchCategoryExperiences.
  ///
  /// In es, this message translates to:
  /// **'Experiencias'**
  String get searchCategoryExperiences;

  /// No description provided for @searchCategoryExperiencesDesc.
  ///
  /// In es, this message translates to:
  /// **'Tours, talleres'**
  String get searchCategoryExperiencesDesc;

  /// No description provided for @searchCategoryServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get searchCategoryServices;

  /// No description provided for @searchCategoryServicesDesc.
  ///
  /// In es, this message translates to:
  /// **'Profesionales'**
  String get searchCategoryServicesDesc;

  /// No description provided for @searchCategoryTrending.
  ///
  /// In es, this message translates to:
  /// **'Tendencias'**
  String get searchCategoryTrending;

  /// No description provided for @searchCategoryTrendingDesc.
  ///
  /// In es, this message translates to:
  /// **'Lo más popular'**
  String get searchCategoryTrendingDesc;

  /// No description provided for @searchNearYou.
  ///
  /// In es, this message translates to:
  /// **'Cerca de Ti'**
  String get searchNearYou;

  /// No description provided for @searchNoLocations.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicaciones disponibles'**
  String get searchNoLocations;

  /// No description provided for @searchNoCoords.
  ///
  /// In es, this message translates to:
  /// **'Los listings no tienen coordenadas'**
  String get searchNoCoords;

  /// No description provided for @searchInMap.
  ///
  /// In es, this message translates to:
  /// **'{count} en el mapa'**
  String searchInMap(int count);

  /// No description provided for @searchResults.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 resultado} other{{count} resultados}}'**
  String searchResults(int count);

  /// No description provided for @searchNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get searchNoResults;

  /// No description provided for @searchTryOther.
  ///
  /// In es, this message translates to:
  /// **'Intenta con otros términos de búsqueda'**
  String get searchTryOther;

  /// No description provided for @searchError.
  ///
  /// In es, this message translates to:
  /// **'Error al buscar. Intenta de nuevo.'**
  String get searchError;

  /// No description provided for @bookingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Reservas'**
  String get bookingsTitle;

  /// No description provided for @bookingsUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get bookingsUpcoming;

  /// No description provided for @bookingsPast.
  ///
  /// In es, this message translates to:
  /// **'Pasadas'**
  String get bookingsPast;

  /// No description provided for @bookingsUpcomingCount.
  ///
  /// In es, this message translates to:
  /// **'Próximas ({count})'**
  String bookingsUpcomingCount(int count);

  /// No description provided for @bookingsPastCount.
  ///
  /// In es, this message translates to:
  /// **'Pasadas ({count})'**
  String bookingsPastCount(int count);

  /// No description provided for @bookingsAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get bookingsAll;

  /// No description provided for @bookingsPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get bookingsPending;

  /// No description provided for @bookingsConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas'**
  String get bookingsConfirmed;

  /// No description provided for @bookingsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get bookingsCompleted;

  /// No description provided for @bookingsCancelled.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get bookingsCancelled;

  /// No description provided for @bookingsNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No tienes reservas próximas'**
  String get bookingsNoUpcoming;

  /// No description provided for @bookingsNoPast.
  ///
  /// In es, this message translates to:
  /// **'Aún no has completado ninguna reserva'**
  String get bookingsNoPast;

  /// No description provided for @bookingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar reservas'**
  String get bookingsLoadError;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get bookingStatusActive;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get bookingStatusRejected;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingDefault.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get bookingDefault;

  /// No description provided for @bookingDetailError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar la reserva'**
  String get bookingDetailError;

  /// No description provided for @bookingNotFound.
  ///
  /// In es, this message translates to:
  /// **'Reserva no encontrada'**
  String get bookingNotFound;

  /// No description provided for @bookingCheckIn.
  ///
  /// In es, this message translates to:
  /// **'ENTRADA'**
  String get bookingCheckIn;

  /// No description provided for @bookingCheckOut.
  ///
  /// In es, this message translates to:
  /// **'SALIDA'**
  String get bookingCheckOut;

  /// No description provided for @bookingNights.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 noche} other{{count} noches}}'**
  String bookingNights(int count);

  /// No description provided for @bookingPeople.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 persona} other{{count} personas}}'**
  String bookingPeople(int count);

  /// No description provided for @bookingHost.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get bookingHost;

  /// No description provided for @bookingPriceBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Desglose de Precio'**
  String get bookingPriceBreakdown;

  /// No description provided for @bookingCleaningFee.
  ///
  /// In es, this message translates to:
  /// **'Tarifa de limpieza'**
  String get bookingCleaningFee;

  /// No description provided for @bookingServiceFee.
  ///
  /// In es, this message translates to:
  /// **'Tarifa de servicio Atrio'**
  String get bookingServiceFee;

  /// No description provided for @bookingTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// No description provided for @bookingPolicies.
  ///
  /// In es, this message translates to:
  /// **'Políticas'**
  String get bookingPolicies;

  /// No description provided for @bookingPolicyFlexTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelación flexible'**
  String get bookingPolicyFlexTitle;

  /// No description provided for @bookingPolicyFlexDesc.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 24h antes de la entrada'**
  String get bookingPolicyFlexDesc;

  /// No description provided for @bookingPolicyNoSmokeTitle.
  ///
  /// In es, this message translates to:
  /// **'No fumar'**
  String get bookingPolicyNoSmokeTitle;

  /// No description provided for @bookingPolicyNoSmokeDesc.
  ///
  /// In es, this message translates to:
  /// **'Prohibido fumar dentro del espacio'**
  String get bookingPolicyNoSmokeDesc;

  /// No description provided for @bookingPolicyHoursTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios'**
  String get bookingPolicyHoursTitle;

  /// No description provided for @bookingPolicyHoursConsult.
  ///
  /// In es, this message translates to:
  /// **'Consultar con el anfitrión'**
  String get bookingPolicyHoursConsult;

  /// No description provided for @bookingConfirmBooking.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Reserva'**
  String get bookingConfirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get bookingConfirmed;

  /// No description provided for @bookingRejectBooking.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Reserva'**
  String get bookingRejectBooking;

  /// No description provided for @bookingRejectConfirmDesc.
  ///
  /// In es, this message translates to:
  /// **'El huésped será notificado y podrá buscar otra opción.'**
  String get bookingRejectConfirmDesc;

  /// No description provided for @bookingRejectYes.
  ///
  /// In es, this message translates to:
  /// **'Sí, rechazar'**
  String get bookingRejectYes;

  /// No description provided for @bookingRejected.
  ///
  /// In es, this message translates to:
  /// **'Reserva rechazada'**
  String get bookingRejected;

  /// No description provided for @bookingContactHost.
  ///
  /// In es, this message translates to:
  /// **'Contactar Anfitrión'**
  String get bookingContactHost;

  /// No description provided for @bookingCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Reserva'**
  String get bookingCancel;

  /// No description provided for @bookingCancelConfirmDesc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer. Si cancelas, perderás tu reserva en \"{title}\".'**
  String bookingCancelConfirmDesc(String title);

  /// No description provided for @bookingCancelInfo.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 24h antes de la entrada'**
  String get bookingCancelInfo;

  /// No description provided for @bookingCancelYes.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar reserva'**
  String get bookingCancelYes;

  /// No description provided for @bookingCancelNo.
  ///
  /// In es, this message translates to:
  /// **'No, mantener reserva'**
  String get bookingCancelNo;

  /// No description provided for @bookingCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada correctamente'**
  String get bookingCancelled;

  /// No description provided for @bookingCancelSimple.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get bookingCancelSimple;

  /// No description provided for @bookingWriteReview.
  ///
  /// In es, this message translates to:
  /// **'Escribir Reseña'**
  String get bookingWriteReview;

  /// No description provided for @bookingPriceLineFormat.
  ///
  /// In es, this message translates to:
  /// **'{price} x {count, plural, one{{count} {unit}} other{{count} {unit}s}}'**
  String bookingPriceLineFormat(String price, int count, String unit);

  /// No description provided for @bookingPolicyHoursFormat.
  ///
  /// In es, this message translates to:
  /// **'Entrada: {checkIn} • Salida: {checkOut}'**
  String bookingPolicyHoursFormat(String checkIn, String checkOut);

  /// No description provided for @bookingTotalWithCurrency.
  ///
  /// In es, this message translates to:
  /// **'{total} CLP'**
  String bookingTotalWithCurrency(String total);

  /// No description provided for @chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get chatTitle;

  /// No description provided for @chatSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar conversaciones...'**
  String get chatSearchHint;

  /// No description provided for @chatLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar mensajes'**
  String get chatLoadError;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes aún'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando reserves un espacio, podrás\ncomunicarte con el anfitrión aquí'**
  String get chatEmptySubtitle;

  /// No description provided for @chatExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar Espacios'**
  String get chatExplore;

  /// No description provided for @chatYou.
  ///
  /// In es, this message translates to:
  /// **'Tú: '**
  String get chatYou;

  /// No description provided for @chatDefault.
  ///
  /// In es, this message translates to:
  /// **'Conversación'**
  String get chatDefault;

  /// No description provided for @chatMsgHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatMsgHint;

  /// No description provided for @chatOnline.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get chatOnline;

  /// No description provided for @chatDeleted.
  ///
  /// In es, this message translates to:
  /// **'Mensaje eliminado'**
  String get chatDeleted;

  /// No description provided for @chatDateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get chatDateYesterday;

  /// No description provided for @chatTyping.
  ///
  /// In es, this message translates to:
  /// **'Escribiendo...'**
  String get chatTyping;

  /// No description provided for @chatStartConversation.
  ///
  /// In es, this message translates to:
  /// **'Inicia la conversación'**
  String get chatStartConversation;

  /// No description provided for @chatTooLong.
  ///
  /// In es, this message translates to:
  /// **'El mensaje es demasiado largo (máx 5000 caracteres)'**
  String get chatTooLong;

  /// No description provided for @chatImageTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen es demasiado grande (máx 5 MB)'**
  String get chatImageTooLarge;

  /// No description provided for @chatGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get chatGallery;

  /// No description provided for @chatCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get chatCamera;

  /// No description provided for @chatImageLabel.
  ///
  /// In es, this message translates to:
  /// **'📷 Imagen'**
  String get chatImageLabel;

  /// No description provided for @chatCopyText.
  ///
  /// In es, this message translates to:
  /// **'Copiar texto'**
  String get chatCopyText;

  /// No description provided for @chatEditMessage.
  ///
  /// In es, this message translates to:
  /// **'Editar mensaje'**
  String get chatEditMessage;

  /// No description provided for @chatTextCopied.
  ///
  /// In es, this message translates to:
  /// **'Texto copiado'**
  String get chatTextCopied;

  /// No description provided for @chatDeleteImage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get chatDeleteImage;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mensaje'**
  String get chatDeleteMessage;

  /// No description provided for @chatDeleteImageConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta imagen para todos? Esta acción no se puede deshacer.'**
  String get chatDeleteImageConfirm;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este mensaje para todos? Esta acción no se puede deshacer.'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatViewListing.
  ///
  /// In es, this message translates to:
  /// **'Ver publicación'**
  String get chatViewListing;

  /// No description provided for @chatClearMyMessages.
  ///
  /// In es, this message translates to:
  /// **'Borrar mis mensajes'**
  String get chatClearMyMessages;

  /// No description provided for @chatClearMyMessagesDesc.
  ///
  /// In es, this message translates to:
  /// **'Elimina todos los mensajes que enviaste en esta conversación'**
  String get chatClearMyMessagesDesc;

  /// No description provided for @chatReport.
  ///
  /// In es, this message translates to:
  /// **'Reportar conversación'**
  String get chatReport;

  /// No description provided for @chatClearConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar todos los mensajes que enviaste en esta conversación? Esta acción no se puede deshacer.'**
  String get chatClearConfirm;

  /// No description provided for @chatClearAll.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get chatClearAll;

  /// No description provided for @chatMessagesCleared.
  ///
  /// In es, this message translates to:
  /// **'Mensajes eliminados'**
  String get chatMessagesCleared;

  /// No description provided for @chatReportAnon.
  ///
  /// In es, this message translates to:
  /// **'Tu reporte es anónimo. Lo revisaremos en menos de 48h.'**
  String get chatReportAnon;

  /// No description provided for @chatReportReasonSpam.
  ///
  /// In es, this message translates to:
  /// **'Spam o publicidad'**
  String get chatReportReasonSpam;

  /// No description provided for @chatReportReasonScam.
  ///
  /// In es, this message translates to:
  /// **'Estafa o fraude'**
  String get chatReportReasonScam;

  /// No description provided for @chatReportReasonHarass.
  ///
  /// In es, this message translates to:
  /// **'Acoso o lenguaje ofensivo'**
  String get chatReportReasonHarass;

  /// No description provided for @chatReportReasonInappropriate.
  ///
  /// In es, this message translates to:
  /// **'Contenido inapropiado'**
  String get chatReportReasonInappropriate;

  /// No description provided for @chatReportReasonImpersonation.
  ///
  /// In es, this message translates to:
  /// **'Suplantación de identidad'**
  String get chatReportReasonImpersonation;

  /// No description provided for @chatReportReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get chatReportReasonOther;

  /// No description provided for @chatReportDetailsHint.
  ///
  /// In es, this message translates to:
  /// **'Detalles adicionales (opcional)'**
  String get chatReportDetailsHint;

  /// No description provided for @chatSendReport.
  ///
  /// In es, this message translates to:
  /// **'Enviar reporte'**
  String get chatSendReport;

  /// No description provided for @chatReportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. Gracias por avisarnos.'**
  String get chatReportSent;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In es, this message translates to:
  /// **'Mensaje eliminado'**
  String get chatMessageDeleted;

  /// No description provided for @chatEdited.
  ///
  /// In es, this message translates to:
  /// **'editado'**
  String get chatEdited;

  /// No description provided for @chatToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get chatYesterday;

  /// No description provided for @chatSaveBtn.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get chatSaveBtn;

  /// No description provided for @checkoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de reserva'**
  String get checkoutSummary;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutTotal.
  ///
  /// In es, this message translates to:
  /// **'Total a pagar'**
  String get checkoutTotal;

  /// No description provided for @checkoutPay.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get checkoutPay;

  /// No description provided for @checkoutProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando pago...'**
  String get checkoutProcessing;

  /// No description provided for @checkoutError.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar el pago'**
  String get checkoutError;

  /// No description provided for @checkoutConfirmedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Reserva confirmada!'**
  String get checkoutConfirmedTitle;

  /// No description provided for @checkoutConfirmedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva ha sido procesada exitosamente'**
  String get checkoutConfirmedSubtitle;

  /// No description provided for @bookingConfirmedMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud ha sido enviada al anfitrión.\nTe notificaremos cuando sea confirmada.'**
  String get bookingConfirmedMessage;

  /// No description provided for @bookingConfirmedNotificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get bookingConfirmedNotificationTitle;

  /// No description provided for @bookingConfirmedNotificationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibirás un aviso'**
  String get bookingConfirmedNotificationSubtitle;

  /// No description provided for @bookingConfirmedChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get bookingConfirmedChatTitle;

  /// No description provided for @bookingConfirmedChatSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Contacta al anfitrión'**
  String get bookingConfirmedChatSubtitle;

  /// No description provided for @bookingConfirmedViewBookings.
  ///
  /// In es, this message translates to:
  /// **'Ver Mis Reservas'**
  String get bookingConfirmedViewBookings;

  /// No description provided for @bookingConfirmedBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al Inicio'**
  String get bookingConfirmedBackHome;

  /// No description provided for @checkoutViewBooking.
  ///
  /// In es, this message translates to:
  /// **'Ver reserva'**
  String get checkoutViewBooking;

  /// No description provided for @checkoutBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get checkoutBackHome;

  /// No description provided for @checkoutPaymentWebTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago seguro'**
  String get checkoutPaymentWebTitle;

  /// No description provided for @paymentWebCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pago'**
  String get paymentWebCancelTitle;

  /// No description provided for @paymentWebCancelMessage.
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, tu reserva quedará pendiente de pago. Puedes reintentar el pago desde tus reservas.'**
  String get paymentWebCancelMessage;

  /// No description provided for @paymentWebKeepPaying.
  ///
  /// In es, this message translates to:
  /// **'Seguir pagando'**
  String get paymentWebKeepPaying;

  /// No description provided for @paymentWebExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get paymentWebExit;

  /// No description provided for @paymentWebLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando checkout seguro...'**
  String get paymentWebLoading;

  /// No description provided for @createListingTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Listado'**
  String get createListingTitle;

  /// No description provided for @createListingBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get createListingBack;

  /// No description provided for @createListingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get createListingContinue;

  /// No description provided for @createListingPublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get createListingPublish;

  /// No description provided for @createListingType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de publicación'**
  String get createListingType;

  /// No description provided for @createListingTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get createListingTitleLabel;

  /// No description provided for @createListingDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get createListingDescription;

  /// No description provided for @createListingLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get createListingLocation;

  /// No description provided for @createListingPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get createListingPrice;

  /// No description provided for @createListingImages.
  ///
  /// In es, this message translates to:
  /// **'Imágenes'**
  String get createListingImages;

  /// No description provided for @createListingSuccess.
  ///
  /// In es, this message translates to:
  /// **'Listado publicado'**
  String get createListingSuccess;

  /// No description provided for @disputesTitle.
  ///
  /// In es, this message translates to:
  /// **'Disputas'**
  String get disputesTitle;

  /// No description provided for @disputesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes disputas activas'**
  String get disputesEmpty;

  /// No description provided for @disputeDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de disputa'**
  String get disputeDetailTitle;

  /// No description provided for @disputeOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir disputa'**
  String get disputeOpen;

  /// No description provided for @disputeReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get disputeReason;

  /// No description provided for @disputeDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get disputeDescription;

  /// No description provided for @hostAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Analíticas'**
  String get hostAnalyticsTitle;

  /// No description provided for @hostAnalyticsRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get hostAnalyticsRevenue;

  /// No description provided for @hostAnalyticsBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get hostAnalyticsBookings;

  /// No description provided for @hostAnalyticsViews.
  ///
  /// In es, this message translates to:
  /// **'Visitas'**
  String get hostAnalyticsViews;

  /// No description provided for @hostAnalyticsRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get hostAnalyticsRating;

  /// No description provided for @hostAnalyticsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar analíticas'**
  String get hostAnalyticsLoadError;

  /// No description provided for @hostAnalyticsPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get hostAnalyticsPeriodWeek;

  /// No description provided for @hostAnalyticsPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get hostAnalyticsPeriodMonth;

  /// No description provided for @hostAnalyticsPeriodYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get hostAnalyticsPeriodYear;

  /// No description provided for @hostAnalyticsRevenueOfPeriod.
  ///
  /// In es, this message translates to:
  /// **'Ingresos del período'**
  String get hostAnalyticsRevenueOfPeriod;

  /// No description provided for @hostAnalyticsReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get hostAnalyticsReviews;

  /// No description provided for @hostAnalyticsTopListings.
  ///
  /// In es, this message translates to:
  /// **'Top Publicaciones'**
  String get hostAnalyticsTopListings;

  /// No description provided for @hostAnalyticsNoListings.
  ///
  /// In es, this message translates to:
  /// **'Sin publicaciones aún'**
  String get hostAnalyticsNoListings;

  /// No description provided for @hostAnalyticsNoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get hostAnalyticsNoTitle;

  /// No description provided for @hostAnalyticsReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} reseñas'**
  String hostAnalyticsReviewsCount(int count);

  /// No description provided for @hostAnalyticsRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad Reciente'**
  String get hostAnalyticsRecentActivity;

  /// No description provided for @hostAnalyticsNoRecentBookings.
  ///
  /// In es, this message translates to:
  /// **'Sin reservas recientes'**
  String get hostAnalyticsNoRecentBookings;

  /// No description provided for @hostAnalyticsBookingFallback.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get hostAnalyticsBookingFallback;

  /// No description provided for @hostBenefitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Beneficios del Anfitrión'**
  String get hostBenefitsTitle;

  /// No description provided for @hostBenefitsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre todo lo que obtienes al publicar en Atrio'**
  String get hostBenefitsSubtitle;

  /// No description provided for @hostBenefitsStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar ahora'**
  String get hostBenefitsStart;

  /// No description provided for @hostBenefitsAppBarTitle.
  ///
  /// In es, this message translates to:
  /// **'Beneficios Atrio'**
  String get hostBenefitsAppBarTitle;

  /// No description provided for @hostBenefitsHeadline.
  ///
  /// In es, this message translates to:
  /// **'Las comisiones más bajas del mercado'**
  String get hostBenefitsHeadline;

  /// No description provided for @hostBenefitsCommissionTitle.
  ///
  /// In es, this message translates to:
  /// **'7% de comisión estándar'**
  String get hostBenefitsCommissionTitle;

  /// No description provided for @hostBenefitsCommissionDesc.
  ///
  /// In es, this message translates to:
  /// **'Comisión transparente del 7% sobre cada reserva completada.'**
  String get hostBenefitsCommissionDesc;

  /// No description provided for @hostBenefitsCapTitle.
  ///
  /// In es, this message translates to:
  /// **'Tope máximo de \$90.000 CLP'**
  String get hostBenefitsCapTitle;

  /// No description provided for @hostBenefitsCapDesc.
  ///
  /// In es, this message translates to:
  /// **'Si el 7% supera \$90.000, solo se cobra \$90.000. Ejemplo: en una reserva de \$5.000.000, pagas \$90.000 en vez de \$350.000.'**
  String get hostBenefitsCapDesc;

  /// No description provided for @hostBenefitsGamificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Gamificación por calidad'**
  String get hostBenefitsGamificationTitle;

  /// No description provided for @hostBenefitsGamificationDesc.
  ///
  /// In es, this message translates to:
  /// **'Mantén 4.5+ estrellas y accede a beneficios exclusivos y mayor visibilidad.'**
  String get hostBenefitsGamificationDesc;

  /// No description provided for @calendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendarTitle;

  /// No description provided for @calendarNoEvents.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos'**
  String get calendarNoEvents;

  /// No description provided for @calendarSignIn.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get calendarSignIn;

  /// No description provided for @calendarEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Publica un anuncio para ver\nel calendario'**
  String get calendarEmptyMessage;

  /// No description provided for @calendarCreateListing.
  ///
  /// In es, this message translates to:
  /// **'Crear anuncio'**
  String get calendarCreateListing;

  /// No description provided for @calendarLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get calendarLoadError;

  /// No description provided for @calendarToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get calendarToday;

  /// No description provided for @calendarNoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get calendarNoTitle;

  /// No description provided for @calendarStatReservations.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get calendarStatReservations;

  /// No description provided for @calendarStatBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueados'**
  String get calendarStatBlocked;

  /// No description provided for @calendarStatAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get calendarStatAvailable;

  /// No description provided for @calendarModeDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get calendarModeDay;

  /// No description provided for @calendarModeRange.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get calendarModeRange;

  /// No description provided for @calendarLegendReserved.
  ///
  /// In es, this message translates to:
  /// **'Reservado'**
  String get calendarLegendReserved;

  /// No description provided for @calendarLegendBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get calendarLegendBlocked;

  /// No description provided for @calendarLegendAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get calendarLegendAvailable;

  /// No description provided for @calendarLegendSelection.
  ///
  /// In es, this message translates to:
  /// **'Selección'**
  String get calendarLegendSelection;

  /// No description provided for @calendarCannotBlockBooked.
  ///
  /// In es, this message translates to:
  /// **'No puedes bloquear una fecha con reserva activa'**
  String get calendarCannotBlockBooked;

  /// No description provided for @calendarUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar disponibilidad'**
  String get calendarUpdateError;

  /// No description provided for @calendarCannotBlockRangeBooked.
  ///
  /// In es, this message translates to:
  /// **'No puedes bloquear fechas con reservas activas'**
  String get calendarCannotBlockRangeBooked;

  /// No description provided for @calendarDatesBlocked.
  ///
  /// In es, this message translates to:
  /// **'Fechas bloqueadas correctamente'**
  String get calendarDatesBlocked;

  /// No description provided for @calendarBlockRangeError.
  ///
  /// In es, this message translates to:
  /// **'Error al bloquear rango'**
  String get calendarBlockRangeError;

  /// No description provided for @calendarDatesUnblocked.
  ///
  /// In es, this message translates to:
  /// **'Fechas desbloqueadas correctamente'**
  String get calendarDatesUnblocked;

  /// No description provided for @calendarUnblockRangeError.
  ///
  /// In es, this message translates to:
  /// **'Error al desbloquear rango'**
  String get calendarUnblockRangeError;

  /// No description provided for @calendarStatusReservedWith.
  ///
  /// In es, this message translates to:
  /// **'Reservado ({status})'**
  String calendarStatusReservedWith(String status);

  /// No description provided for @calendarStatusReserved.
  ///
  /// In es, this message translates to:
  /// **'Reservado'**
  String get calendarStatusReserved;

  /// No description provided for @calendarStatusBlockedManually.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado manualmente'**
  String get calendarStatusBlockedManually;

  /// No description provided for @calendarStatusAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get calendarStatusAvailable;

  /// No description provided for @calendarStatusBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get calendarStatusBlocked;

  /// No description provided for @calendarViewBooking.
  ///
  /// In es, this message translates to:
  /// **'Ver reserva'**
  String get calendarViewBooking;

  /// No description provided for @calendarUnblockDay.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear día'**
  String get calendarUnblockDay;

  /// No description provided for @calendarBlockDay.
  ///
  /// In es, this message translates to:
  /// **'Bloquear día'**
  String get calendarBlockDay;

  /// No description provided for @calendarBlock.
  ///
  /// In es, this message translates to:
  /// **'Bloquear'**
  String get calendarBlock;

  /// No description provided for @calendarUnblock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get calendarUnblock;

  /// No description provided for @calendarSelectStartDate.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la fecha inicial'**
  String get calendarSelectStartDate;

  /// No description provided for @calendarSelectEndDate.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la fecha final'**
  String get calendarSelectEndDate;

  /// No description provided for @calendarViewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get calendarViewDetails;

  /// No description provided for @calendarMonthJan.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get calendarMonthJan;

  /// No description provided for @calendarMonthFeb.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get calendarMonthFeb;

  /// No description provided for @calendarMonthMar.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get calendarMonthMar;

  /// No description provided for @calendarMonthApr.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get calendarMonthApr;

  /// No description provided for @calendarMonthMay.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get calendarMonthMay;

  /// No description provided for @calendarMonthJun.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get calendarMonthJun;

  /// No description provided for @calendarMonthJul.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get calendarMonthJul;

  /// No description provided for @calendarMonthAug.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get calendarMonthAug;

  /// No description provided for @calendarMonthSep.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get calendarMonthSep;

  /// No description provided for @calendarMonthOct.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get calendarMonthOct;

  /// No description provided for @calendarMonthNov.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get calendarMonthNov;

  /// No description provided for @calendarMonthDec.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get calendarMonthDec;

  /// No description provided for @calendarDayShortMon.
  ///
  /// In es, this message translates to:
  /// **'Lu'**
  String get calendarDayShortMon;

  /// No description provided for @calendarDayShortTue.
  ///
  /// In es, this message translates to:
  /// **'Ma'**
  String get calendarDayShortTue;

  /// No description provided for @calendarDayShortWed.
  ///
  /// In es, this message translates to:
  /// **'Mi'**
  String get calendarDayShortWed;

  /// No description provided for @calendarDayShortThu.
  ///
  /// In es, this message translates to:
  /// **'Ju'**
  String get calendarDayShortThu;

  /// No description provided for @calendarDayShortFri.
  ///
  /// In es, this message translates to:
  /// **'Vi'**
  String get calendarDayShortFri;

  /// No description provided for @calendarDayShortSat.
  ///
  /// In es, this message translates to:
  /// **'Sa'**
  String get calendarDayShortSat;

  /// No description provided for @calendarDayShortSun.
  ///
  /// In es, this message translates to:
  /// **'Do'**
  String get calendarDayShortSun;

  /// No description provided for @calendarDayAbbrMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get calendarDayAbbrMon;

  /// No description provided for @calendarDayAbbrTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get calendarDayAbbrTue;

  /// No description provided for @calendarDayAbbrWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get calendarDayAbbrWed;

  /// No description provided for @calendarDayAbbrThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get calendarDayAbbrThu;

  /// No description provided for @calendarDayAbbrFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get calendarDayAbbrFri;

  /// No description provided for @calendarDayAbbrSat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get calendarDayAbbrSat;

  /// No description provided for @calendarDayAbbrSun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get calendarDayAbbrSun;

  /// No description provided for @calendarDayFullMon.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get calendarDayFullMon;

  /// No description provided for @calendarDayFullTue.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get calendarDayFullTue;

  /// No description provided for @calendarDayFullWed.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get calendarDayFullWed;

  /// No description provided for @calendarDayFullThu.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get calendarDayFullThu;

  /// No description provided for @calendarDayFullFri.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get calendarDayFullFri;

  /// No description provided for @calendarDayFullSat.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get calendarDayFullSat;

  /// No description provided for @calendarDayFullSun.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get calendarDayFullSun;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get dashboardTitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get dashboardEarnings;

  /// No description provided for @dashboardBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get dashboardBookings;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get dashboardGoodMorning;

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get dashboardGoodAfternoon;

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get dashboardGoodEvening;

  /// No description provided for @dashboardHostFallback.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get dashboardHostFallback;

  /// No description provided for @dashboardTotalEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ganancias totales'**
  String get dashboardTotalEarnings;

  /// No description provided for @dashboardAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get dashboardAvailable;

  /// No description provided for @dashboardPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get dashboardPending;

  /// No description provided for @dashboardPeriod1W.
  ///
  /// In es, this message translates to:
  /// **'1S'**
  String get dashboardPeriod1W;

  /// No description provided for @dashboardPeriod1M.
  ///
  /// In es, this message translates to:
  /// **'1M'**
  String get dashboardPeriod1M;

  /// No description provided for @dashboardPeriod3M.
  ///
  /// In es, this message translates to:
  /// **'3M'**
  String get dashboardPeriod3M;

  /// No description provided for @dashboardPeriod6M.
  ///
  /// In es, this message translates to:
  /// **'6M'**
  String get dashboardPeriod6M;

  /// No description provided for @dashboardPeriod1Y.
  ///
  /// In es, this message translates to:
  /// **'1A'**
  String get dashboardPeriod1Y;

  /// No description provided for @dashboardPeriodAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get dashboardPeriodAll;

  /// No description provided for @dashboardNoRevenueInPeriod.
  ///
  /// In es, this message translates to:
  /// **'Sin ingresos en este período'**
  String get dashboardNoRevenueInPeriod;

  /// No description provided for @dashboardActiveBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas\nActivas'**
  String get dashboardActiveBookings;

  /// No description provided for @dashboardOccupancy.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get dashboardOccupancy;

  /// No description provided for @dashboardRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get dashboardRating;

  /// No description provided for @dashboardUpcomingBookings.
  ///
  /// In es, this message translates to:
  /// **'Próximas Reservas'**
  String get dashboardUpcomingBookings;

  /// No description provided for @dashboardNoUpcomingBookings.
  ///
  /// In es, this message translates to:
  /// **'No hay reservas próximas'**
  String get dashboardNoUpcomingBookings;

  /// No description provided for @dashboardGuestFallback.
  ///
  /// In es, this message translates to:
  /// **'Huésped'**
  String get dashboardGuestFallback;

  /// No description provided for @dashboardListingFallback.
  ///
  /// In es, this message translates to:
  /// **'Espacio'**
  String get dashboardListingFallback;

  /// No description provided for @dashboardStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get dashboardStatusPending;

  /// No description provided for @dashboardStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get dashboardStatusConfirmed;

  /// No description provided for @dashboardViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get dashboardViewAll;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad Reciente'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'No hay actividad reciente'**
  String get dashboardNoRecentActivity;

  /// No description provided for @dashboardLoadActivityError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar actividad'**
  String get dashboardLoadActivityError;

  /// No description provided for @dashboardViewFullAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Ver analíticas completas'**
  String get dashboardViewFullAnalytics;

  /// No description provided for @dashboardTimeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get dashboardTimeNow;

  /// No description provided for @dashboardTimeDays.
  ///
  /// In es, this message translates to:
  /// **'Hace {d}d'**
  String dashboardTimeDays(int d);

  /// No description provided for @dashboardTimeHours.
  ///
  /// In es, this message translates to:
  /// **'Hace {h}h'**
  String dashboardTimeHours(int h);

  /// No description provided for @dashboardTimeMins.
  ///
  /// In es, this message translates to:
  /// **'Hace {m}m'**
  String dashboardTimeMins(int m);

  /// No description provided for @dashboardDayShortMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get dashboardDayShortMon;

  /// No description provided for @dashboardDayShortTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get dashboardDayShortTue;

  /// No description provided for @dashboardDayShortWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get dashboardDayShortWed;

  /// No description provided for @dashboardDayShortThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get dashboardDayShortThu;

  /// No description provided for @dashboardDayShortFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get dashboardDayShortFri;

  /// No description provided for @dashboardDayShortSat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get dashboardDayShortSat;

  /// No description provided for @dashboardDayShortSun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get dashboardDayShortSun;

  /// No description provided for @dashboardWeekPrefix.
  ///
  /// In es, this message translates to:
  /// **'S{num}'**
  String dashboardWeekPrefix(int num);

  /// No description provided for @hostListingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Listados'**
  String get hostListingsTitle;

  /// No description provided for @hostListingsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes listados'**
  String get hostListingsEmpty;

  /// No description provided for @hostListingsCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear listado'**
  String get hostListingsCreate;

  /// No description provided for @hostListingsHeader.
  ///
  /// In es, this message translates to:
  /// **'Mis Espacios'**
  String get hostListingsHeader;

  /// No description provided for @hostListingsKeepRate.
  ///
  /// In es, this message translates to:
  /// **'Tu recibes el {rate}% de tus ingresos'**
  String hostListingsKeepRate(String rate);

  /// No description provided for @hostListingsNoListingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin publicaciones aún'**
  String get hostListingsNoListingsTitle;

  /// No description provided for @hostListingsNoListingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer anuncio y comienza\na generar ingresos'**
  String get hostListingsNoListingsSubtitle;

  /// No description provided for @hostListingsCreateListingBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear Anuncio'**
  String get hostListingsCreateListingBtn;

  /// No description provided for @hostListingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar anuncios'**
  String get hostListingsLoadError;

  /// No description provided for @hostListingsNoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get hostListingsNoTitle;

  /// No description provided for @hostListingsViewsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} vistas'**
  String hostListingsViewsCount(int count);

  /// No description provided for @hostListingsViewListing.
  ///
  /// In es, this message translates to:
  /// **'Ver anuncio'**
  String get hostListingsViewListing;

  /// No description provided for @hostListingsPauseListing.
  ///
  /// In es, this message translates to:
  /// **'Pausar anuncio'**
  String get hostListingsPauseListing;

  /// No description provided for @hostListingsPublishListing.
  ///
  /// In es, this message translates to:
  /// **'Publicar anuncio'**
  String get hostListingsPublishListing;

  /// No description provided for @hostListingsDeleteListing.
  ///
  /// In es, this message translates to:
  /// **'Eliminar anuncio'**
  String get hostListingsDeleteListing;

  /// No description provided for @hostListingsDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{title}\" permanentemente. Esta acción no se puede deshacer.'**
  String hostListingsDeleteConfirm(String title);

  /// No description provided for @hostListingsDeletedSnack.
  ///
  /// In es, this message translates to:
  /// **'Anuncio eliminado'**
  String get hostListingsDeletedSnack;

  /// No description provided for @hostListingsStatusPublished.
  ///
  /// In es, this message translates to:
  /// **'Publicado'**
  String get hostListingsStatusPublished;

  /// No description provided for @hostListingsStatusDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get hostListingsStatusDraft;

  /// No description provided for @hostListingsStatusPaused.
  ///
  /// In es, this message translates to:
  /// **'Pausado'**
  String get hostListingsStatusPaused;

  /// No description provided for @walletTitle.
  ///
  /// In es, this message translates to:
  /// **'Billetera'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo disponible'**
  String get walletBalance;

  /// No description provided for @walletPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get walletPending;

  /// No description provided for @walletTotalEarned.
  ///
  /// In es, this message translates to:
  /// **'Total ganado'**
  String get walletTotalEarned;

  /// No description provided for @walletWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get walletWithdraw;

  /// No description provided for @walletHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get walletHeaderTitle;

  /// No description provided for @walletAvailableForWithdrawal.
  ///
  /// In es, this message translates to:
  /// **'Disponible para retiro'**
  String get walletAvailableForWithdrawal;

  /// No description provided for @walletWithdrawBtn.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get walletWithdrawBtn;

  /// No description provided for @walletHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get walletHistory;

  /// No description provided for @walletComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get walletComingSoon;

  /// No description provided for @walletLinkedAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas Vinculadas'**
  String get walletLinkedAccounts;

  /// No description provided for @walletNoLinkedAccounts.
  ///
  /// In es, this message translates to:
  /// **'Sin cuentas vinculadas'**
  String get walletNoLinkedAccounts;

  /// No description provided for @walletLinkBankDesc.
  ///
  /// In es, this message translates to:
  /// **'Vincula una cuenta bancaria para\nrecibir tus pagos'**
  String get walletLinkBankDesc;

  /// No description provided for @walletAddPayoutMethod.
  ///
  /// In es, this message translates to:
  /// **'Agregar Método de Pago'**
  String get walletAddPayoutMethod;

  /// No description provided for @walletAddPayoutComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Agregar método de pago - Próximamente'**
  String get walletAddPayoutComingSoon;

  /// No description provided for @walletRecentTransfers.
  ///
  /// In es, this message translates to:
  /// **'Transferencias Recientes'**
  String get walletRecentTransfers;

  /// No description provided for @walletTransactionFallback.
  ///
  /// In es, this message translates to:
  /// **'Transacción'**
  String get walletTransactionFallback;

  /// No description provided for @walletStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get walletStatusCompleted;

  /// No description provided for @walletNoTransactions.
  ///
  /// In es, this message translates to:
  /// **'Sin transacciones aún'**
  String get walletNoTransactions;

  /// No description provided for @walletNoTransactionsDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus ingresos aparecerán aquí cuando\nrecibas tu primera reserva'**
  String get walletNoTransactionsDesc;

  /// No description provided for @walletLoadTransactionsError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar transacciones'**
  String get walletLoadTransactionsError;

  /// No description provided for @walletViewAllTransactions.
  ///
  /// In es, this message translates to:
  /// **'Ver todas las transacciones'**
  String get walletViewAllTransactions;

  /// No description provided for @walletFullHistoryComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Historial completo - Próximamente'**
  String get walletFullHistoryComingSoon;

  /// No description provided for @walletTaxDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos Fiscales'**
  String get walletTaxDocuments;

  /// No description provided for @walletMonthlyInvoices.
  ///
  /// In es, this message translates to:
  /// **'Facturas Fiscales Mensuales'**
  String get walletMonthlyInvoices;

  /// No description provided for @walletMonthlyInvoicesDesc.
  ///
  /// In es, this message translates to:
  /// **'Descarga resúmenes mensuales de ingresos'**
  String get walletMonthlyInvoicesDesc;

  /// No description provided for @walletAvailableWhenActivity.
  ///
  /// In es, this message translates to:
  /// **'Disponible cuando tengas actividad financiera'**
  String get walletAvailableWhenActivity;

  /// No description provided for @walletNotificationPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias de Notificación'**
  String get walletNotificationPreferences;

  /// No description provided for @walletEmailReceipts.
  ///
  /// In es, this message translates to:
  /// **'Recibos por Correo'**
  String get walletEmailReceipts;

  /// No description provided for @walletEmailReceiptsDesc.
  ///
  /// In es, this message translates to:
  /// **'Confirmaciones de transacciones por email'**
  String get walletEmailReceiptsDesc;

  /// No description provided for @walletPushNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones Push'**
  String get walletPushNotifications;

  /// No description provided for @walletPushNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Alertas instantáneas en tu dispositivo'**
  String get walletPushNotificationsDesc;

  /// No description provided for @walletSmsAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas SMS'**
  String get walletSmsAlerts;

  /// No description provided for @walletSmsAlertsDesc.
  ///
  /// In es, this message translates to:
  /// **'Mensajes de texto para retiros grandes'**
  String get walletSmsAlertsDesc;

  /// No description provided for @walletNotificationsFooter.
  ///
  /// In es, this message translates to:
  /// **'Administra cómo recibes actualizaciones sobre retiros, transferencias y actividad financiera en tu cuenta.'**
  String get walletNotificationsFooter;

  /// No description provided for @listingAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca del lugar'**
  String get listingAbout;

  /// No description provided for @listingAmenities.
  ///
  /// In es, this message translates to:
  /// **'Amenidades'**
  String get listingAmenities;

  /// No description provided for @listingLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get listingLocation;

  /// No description provided for @listingReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get listingReviews;

  /// No description provided for @listingHost.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get listingHost;

  /// No description provided for @listingBookNow.
  ///
  /// In es, this message translates to:
  /// **'Reservar'**
  String get listingBookNow;

  /// No description provided for @listingPerNight.
  ///
  /// In es, this message translates to:
  /// **'/ noche'**
  String get listingPerNight;

  /// No description provided for @listingPerHour.
  ///
  /// In es, this message translates to:
  /// **'/ hora'**
  String get listingPerHour;

  /// No description provided for @listingAddFavorites.
  ///
  /// In es, this message translates to:
  /// **'Agregar a favoritos'**
  String get listingAddFavorites;

  /// No description provided for @listingTypeSpace.
  ///
  /// In es, this message translates to:
  /// **'Espacio'**
  String get listingTypeSpace;

  /// No description provided for @listingTypeExperience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia'**
  String get listingTypeExperience;

  /// No description provided for @listingTypeService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get listingTypeService;

  /// No description provided for @listingTypeSpaceLower.
  ///
  /// In es, this message translates to:
  /// **'espacio'**
  String get listingTypeSpaceLower;

  /// No description provided for @listingTypeExperienceLower.
  ///
  /// In es, this message translates to:
  /// **'experiencia'**
  String get listingTypeExperienceLower;

  /// No description provided for @listingTypeServiceLower.
  ///
  /// In es, this message translates to:
  /// **'servicio'**
  String get listingTypeServiceLower;

  /// No description provided for @listingAboutSpace.
  ///
  /// In es, this message translates to:
  /// **'Acerca del espacio'**
  String get listingAboutSpace;

  /// No description provided for @listingAboutExperience.
  ///
  /// In es, this message translates to:
  /// **'Acerca de la experiencia'**
  String get listingAboutExperience;

  /// No description provided for @listingAboutService.
  ///
  /// In es, this message translates to:
  /// **'Acerca del servicio'**
  String get listingAboutService;

  /// No description provided for @listingShareText.
  ///
  /// In es, this message translates to:
  /// **'¡Mira este {typeLabel} en Atrio! {title} - {price}/{unit}'**
  String listingShareText(
    String typeLabel,
    String title,
    String price,
    String unit,
  );

  /// No description provided for @listingReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar publicación'**
  String get listingReportTitle;

  /// No description provided for @listingReportInappropriate.
  ///
  /// In es, this message translates to:
  /// **'Contenido inapropiado'**
  String get listingReportInappropriate;

  /// No description provided for @listingReportFalseInfo.
  ///
  /// In es, this message translates to:
  /// **'Información falsa o engañosa'**
  String get listingReportFalseInfo;

  /// No description provided for @listingReportPhotosMismatch.
  ///
  /// In es, this message translates to:
  /// **'Fotos no coinciden'**
  String get listingReportPhotosMismatch;

  /// No description provided for @listingReportWrongPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio incorrecto'**
  String get listingReportWrongPrice;

  /// No description provided for @listingReportSpam.
  ///
  /// In es, this message translates to:
  /// **'Spam o estafa'**
  String get listingReportSpam;

  /// No description provided for @listingReportOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get listingReportOther;

  /// No description provided for @listingReportSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar reporte'**
  String get listingReportSubmit;

  /// No description provided for @listingReportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. Gracias por ayudarnos a mejorar.'**
  String get listingReportSent;

  /// No description provided for @listingUnitNight.
  ///
  /// In es, this message translates to:
  /// **'noche'**
  String get listingUnitNight;

  /// No description provided for @listingUnitHour.
  ///
  /// In es, this message translates to:
  /// **'hora'**
  String get listingUnitHour;

  /// No description provided for @listingUnitSession.
  ///
  /// In es, this message translates to:
  /// **'sesión'**
  String get listingUnitSession;

  /// No description provided for @listingUnitPerson.
  ///
  /// In es, this message translates to:
  /// **'persona'**
  String get listingUnitPerson;

  /// No description provided for @listingLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get listingLoadError;

  /// No description provided for @listingNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontrado'**
  String get listingNotFound;

  /// No description provided for @listingDefaultHost.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get listingDefaultHost;

  /// No description provided for @listingSuperhostLabel.
  ///
  /// In es, this message translates to:
  /// **'Superhost · '**
  String get listingSuperhostLabel;

  /// No description provided for @listingHostResponseTime.
  ///
  /// In es, this message translates to:
  /// **'Responde en 1hr'**
  String get listingHostResponseTime;

  /// No description provided for @listingChatButton.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get listingChatButton;

  /// No description provided for @listingDescEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción disponible.'**
  String get listingDescEmpty;

  /// No description provided for @listingShowLess.
  ///
  /// In es, this message translates to:
  /// **'Mostrar menos'**
  String get listingShowLess;

  /// No description provided for @listingShowMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get listingShowMore;

  /// No description provided for @listingHighlightPersons.
  ///
  /// In es, this message translates to:
  /// **'{count} pers.'**
  String listingHighlightPersons(int count);

  /// No description provided for @listingHighlightInsured.
  ///
  /// In es, this message translates to:
  /// **'Asegurado'**
  String get listingHighlightInsured;

  /// No description provided for @listingHighlightInstant.
  ///
  /// In es, this message translates to:
  /// **'Inmediato'**
  String get listingHighlightInstant;

  /// No description provided for @listingHighlightConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirm.'**
  String get listingHighlightConfirm;

  /// No description provided for @listingRentalMode.
  ///
  /// In es, this message translates to:
  /// **'Modalidad: {mode}'**
  String listingRentalMode(String mode);

  /// No description provided for @listingRentalHoursSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Disponible {from} - {until} · Mín. {minH, plural, one{1 hora} other{{minH} horas}}'**
  String listingRentalHoursSubtitle(String from, String until, int minH);

  /// No description provided for @listingRentalFullDaySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reserva por día completo'**
  String get listingRentalFullDaySubtitle;

  /// No description provided for @listingRentalNightsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Check-in {checkIn} · Check-out {checkOut} · Mín. {minN, plural, one{1 noche} other{{minN} noches}}'**
  String listingRentalNightsSubtitle(String checkIn, String checkOut, int minN);

  /// No description provided for @listingAvailability.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad'**
  String get listingAvailability;

  /// No description provided for @listingAvailabilityLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la disponibilidad'**
  String get listingAvailabilityLoadError;

  /// No description provided for @listingAvailabilityAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get listingAvailabilityAvailable;

  /// No description provided for @listingAvailabilityBooked.
  ///
  /// In es, this message translates to:
  /// **'Reservado'**
  String get listingAvailabilityBooked;

  /// No description provided for @listingAvailabilityBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get listingAvailabilityBlocked;

  /// No description provided for @listingRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas'**
  String get listingRules;

  /// No description provided for @listingRuleCheckInOut.
  ///
  /// In es, this message translates to:
  /// **'Check-in: {checkIn} — Check-out: {checkOut}'**
  String listingRuleCheckInOut(String checkIn, String checkOut);

  /// No description provided for @listingRuleHours.
  ///
  /// In es, this message translates to:
  /// **'Horario: {from} — {until}'**
  String listingRuleHours(String from, String until);

  /// No description provided for @listingRuleFullDay.
  ///
  /// In es, this message translates to:
  /// **'Día completo disponible'**
  String get listingRuleFullDay;

  /// No description provided for @listingRuleNoSmoke.
  ///
  /// In es, this message translates to:
  /// **'No fumar dentro del espacio'**
  String get listingRuleNoSmoke;

  /// No description provided for @listingRulePets.
  ///
  /// In es, this message translates to:
  /// **'Mascotas con previo aviso'**
  String get listingRulePets;

  /// No description provided for @listingRuleQuiet.
  ///
  /// In es, this message translates to:
  /// **'Respetar horario de silencio'**
  String get listingRuleQuiet;

  /// No description provided for @listingCancellation.
  ///
  /// In es, this message translates to:
  /// **'Cancelación'**
  String get listingCancellation;

  /// No description provided for @listingCancelFlexFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis hasta 48h antes'**
  String get listingCancelFlexFree;

  /// No description provided for @listingCancelFlexFreeDesc.
  ///
  /// In es, this message translates to:
  /// **'Reembolso completo'**
  String get listingCancelFlexFreeDesc;

  /// No description provided for @listingCancelFlexPartial.
  ///
  /// In es, this message translates to:
  /// **'24-48h: 50% reembolso'**
  String get listingCancelFlexPartial;

  /// No description provided for @listingCancelFlexPartialDesc.
  ///
  /// In es, this message translates to:
  /// **'Se retiene la mitad'**
  String get listingCancelFlexPartialDesc;

  /// No description provided for @listingCancelFlexNone.
  ///
  /// In es, this message translates to:
  /// **'Menos de 24h'**
  String get listingCancelFlexNone;

  /// No description provided for @listingCancelFlexNoneDesc.
  ///
  /// In es, this message translates to:
  /// **'Sin reembolso'**
  String get listingCancelFlexNoneDesc;

  /// No description provided for @listingCancelModFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis hasta 5 días antes'**
  String get listingCancelModFree;

  /// No description provided for @listingCancelModFreeDesc.
  ///
  /// In es, this message translates to:
  /// **'Reembolso completo'**
  String get listingCancelModFreeDesc;

  /// No description provided for @listingCancelModPartial.
  ///
  /// In es, this message translates to:
  /// **'2-5 días: 50% reembolso'**
  String get listingCancelModPartial;

  /// No description provided for @listingCancelModPartialDesc.
  ///
  /// In es, this message translates to:
  /// **'Se retiene la mitad'**
  String get listingCancelModPartialDesc;

  /// No description provided for @listingCancelModNone.
  ///
  /// In es, this message translates to:
  /// **'Menos de 2 días'**
  String get listingCancelModNone;

  /// No description provided for @listingCancelModNoneDesc.
  ///
  /// In es, this message translates to:
  /// **'Sin reembolso'**
  String get listingCancelModNoneDesc;

  /// No description provided for @listingCancelStrictFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis hasta 7 días antes'**
  String get listingCancelStrictFree;

  /// No description provided for @listingCancelStrictFreeDesc.
  ///
  /// In es, this message translates to:
  /// **'Reembolso completo'**
  String get listingCancelStrictFreeDesc;

  /// No description provided for @listingCancelStrictPartial.
  ///
  /// In es, this message translates to:
  /// **'3-7 días: 50% reembolso'**
  String get listingCancelStrictPartial;

  /// No description provided for @listingCancelStrictPartialDesc.
  ///
  /// In es, this message translates to:
  /// **'Se retiene la mitad'**
  String get listingCancelStrictPartialDesc;

  /// No description provided for @listingCancelStrictNone.
  ///
  /// In es, this message translates to:
  /// **'Menos de 3 días'**
  String get listingCancelStrictNone;

  /// No description provided for @listingCancelStrictNoneDesc.
  ///
  /// In es, this message translates to:
  /// **'Sin reembolso'**
  String get listingCancelStrictNoneDesc;

  /// No description provided for @listingMonthJan.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get listingMonthJan;

  /// No description provided for @listingMonthFeb.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get listingMonthFeb;

  /// No description provided for @listingMonthMar.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get listingMonthMar;

  /// No description provided for @listingMonthApr.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get listingMonthApr;

  /// No description provided for @listingMonthMay.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get listingMonthMay;

  /// No description provided for @listingMonthJun.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get listingMonthJun;

  /// No description provided for @listingMonthJul.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get listingMonthJul;

  /// No description provided for @listingMonthAug.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get listingMonthAug;

  /// No description provided for @listingMonthSep.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get listingMonthSep;

  /// No description provided for @listingMonthOct.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get listingMonthOct;

  /// No description provided for @listingMonthNov.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get listingMonthNov;

  /// No description provided for @listingMonthDec.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get listingMonthDec;

  /// No description provided for @listingDayMon.
  ///
  /// In es, this message translates to:
  /// **'Lu'**
  String get listingDayMon;

  /// No description provided for @listingDayTue.
  ///
  /// In es, this message translates to:
  /// **'Ma'**
  String get listingDayTue;

  /// No description provided for @listingDayWed.
  ///
  /// In es, this message translates to:
  /// **'Mi'**
  String get listingDayWed;

  /// No description provided for @listingDayThu.
  ///
  /// In es, this message translates to:
  /// **'Ju'**
  String get listingDayThu;

  /// No description provided for @listingDayFri.
  ///
  /// In es, this message translates to:
  /// **'Vi'**
  String get listingDayFri;

  /// No description provided for @listingDaySat.
  ///
  /// In es, this message translates to:
  /// **'Sa'**
  String get listingDaySat;

  /// No description provided for @listingDaySun.
  ///
  /// In es, this message translates to:
  /// **'Do'**
  String get listingDaySun;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In es, this message translates to:
  /// **'Te avisaremos cuando haya algo nuevo'**
  String get notificationsEmptyDesc;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leídas'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar notificaciones'**
  String get notificationsLoadError;

  /// No description provided for @notificationsDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get notificationsDefaultTitle;

  /// No description provided for @notificationsGroupToday.
  ///
  /// In es, this message translates to:
  /// **'HOY'**
  String get notificationsGroupToday;

  /// No description provided for @notificationsGroupYesterday.
  ///
  /// In es, this message translates to:
  /// **'AYER'**
  String get notificationsGroupYesterday;

  /// No description provided for @notificationsGroupThisWeek.
  ///
  /// In es, this message translates to:
  /// **'ESTA SEMANA'**
  String get notificationsGroupThisWeek;

  /// No description provided for @notificationsGroupEarlier.
  ///
  /// In es, this message translates to:
  /// **'ANTERIORES'**
  String get notificationsGroupEarlier;

  /// No description provided for @notificationsTimeMin.
  ///
  /// In es, this message translates to:
  /// **'hace {m}m'**
  String notificationsTimeMin(int m);

  /// No description provided for @notificationsTimeHour.
  ///
  /// In es, this message translates to:
  /// **'hace {h}h'**
  String notificationsTimeHour(int h);

  /// No description provided for @notificationsTimeDay.
  ///
  /// In es, this message translates to:
  /// **'hace {d}d'**
  String notificationsTimeDay(int d);

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In es, this message translates to:
  /// **'Descubre Espacios Únicos'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Lofts, estudios, cabañas y más. Reserva por horas, día completo o noches.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In es, this message translates to:
  /// **'Vive Experiencias Inolvidables'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Trekking, fotografía, tours gastronómicos. Aventuras con cupos limitados.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In es, this message translates to:
  /// **'Servicios a tu Medida'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'DJ, catering, limpieza y más. Contrata profesionales verificados.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEdit;

  /// No description provided for @profileFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get profileFavorites;

  /// No description provided for @profilePaymentMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get profilePaymentMethods;

  /// No description provided for @profileHelpCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de ayuda'**
  String get profileHelpCenter;

  /// No description provided for @profileAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get profileAbout;

  /// No description provided for @profilePrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get profilePrivacy;

  /// No description provided for @profileTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get profileTerms;

  /// No description provided for @profileKyc.
  ///
  /// In es, this message translates to:
  /// **'Verificación de identidad'**
  String get profileKyc;

  /// No description provided for @profileLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogout;

  /// No description provided for @profileSwitchToHost.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a Anfitrión'**
  String get profileSwitchToHost;

  /// No description provided for @profileSwitchToGuest.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a Huésped'**
  String get profileSwitchToGuest;

  /// No description provided for @profileSwitchHostSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus espacios y servicios'**
  String get profileSwitchHostSubtitle;

  /// No description provided for @profileSwitchGuestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora y reserva experiencias'**
  String get profileSwitchGuestSubtitle;

  /// No description provided for @profileUserFallback.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get profileUserFallback;

  /// No description provided for @profileVerifiedMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro Verificado'**
  String get profileVerifiedMember;

  /// No description provided for @profileJoinedYear.
  ///
  /// In es, this message translates to:
  /// **'Desde {year}'**
  String profileJoinedYear(int year);

  /// No description provided for @profileStatBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get profileStatBookings;

  /// No description provided for @profileStatRating.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get profileStatRating;

  /// No description provided for @profileStatResponse.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get profileStatResponse;

  /// No description provided for @profileStatReliability.
  ///
  /// In es, this message translates to:
  /// **'Fiabilidad'**
  String get profileStatReliability;

  /// No description provided for @profileStatCancellations.
  ///
  /// In es, this message translates to:
  /// **'Cancelaciones'**
  String get profileStatCancellations;

  /// No description provided for @profileSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profileSettings;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In es, this message translates to:
  /// **'Información Personal'**
  String get profilePersonalInfo;

  /// No description provided for @profileNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profileNotifications;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfileTitle;

  /// No description provided for @editProfileName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get editProfileName;

  /// No description provided for @editProfileBio.
  ///
  /// In es, this message translates to:
  /// **'Biografía'**
  String get editProfileBio;

  /// No description provided for @editProfilePhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get editProfilePhone;

  /// No description provided for @editProfileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get editProfileSaved;

  /// No description provided for @editProfileFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get editProfileFullName;

  /// No description provided for @editProfileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get editProfileNameHint;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get editProfileEmailLabel;

  /// No description provided for @editProfilePhoneHint.
  ///
  /// In es, this message translates to:
  /// **'+52 55 1234 5678'**
  String get editProfilePhoneHint;

  /// No description provided for @editProfileAboutYou.
  ///
  /// In es, this message translates to:
  /// **'Acerca de ti'**
  String get editProfileAboutYou;

  /// No description provided for @editProfileAboutHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos algo sobre ti...'**
  String get editProfileAboutHint;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get editProfileSaveChanges;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfilePhotoUpdated.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada'**
  String get editProfilePhotoUpdated;

  /// No description provided for @editProfileUpdatedOk.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado correctamente'**
  String get editProfileUpdatedOk;

  /// No description provided for @favoritesTitle.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes favoritos aún'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin favoritos aún'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyDesc.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus espacios y experiencias\nfavoritos tocando el corazón'**
  String get favoritesEmptyDesc;

  /// No description provided for @favoritesExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get favoritesExplore;

  /// No description provided for @favoritesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar favoritos'**
  String get favoritesLoadError;

  /// No description provided for @favoritesRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get favoritesRetry;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In es, this message translates to:
  /// **'Métodos de Pago'**
  String get paymentMethodsTitle;

  /// No description provided for @paymentMethodsAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar método'**
  String get paymentMethodsAdd;

  /// No description provided for @paymentMethodsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes métodos de pago'**
  String get paymentMethodsEmpty;

  /// No description provided for @pmStripePayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos con Stripe'**
  String get pmStripePayments;

  /// No description provided for @pmStripeTagline.
  ///
  /// In es, this message translates to:
  /// **'Pagos seguros y rápidos'**
  String get pmStripeTagline;

  /// No description provided for @pmActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get pmActive;

  /// No description provided for @pmConnectStripe.
  ///
  /// In es, this message translates to:
  /// **'Conectar con Stripe'**
  String get pmConnectStripe;

  /// No description provided for @pmStripeConnected.
  ///
  /// In es, this message translates to:
  /// **'Stripe conectado exitosamente'**
  String get pmStripeConnected;

  /// No description provided for @pmSavedCards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas Guardadas'**
  String get pmSavedCards;

  /// No description provided for @pmNoSavedCards.
  ///
  /// In es, this message translates to:
  /// **'Sin tarjetas guardadas'**
  String get pmNoSavedCards;

  /// No description provided for @pmNoSavedCardsDesc.
  ///
  /// In es, this message translates to:
  /// **'Agrega una tarjeta para realizar\npagos de forma rápida y segura'**
  String get pmNoSavedCardsDesc;

  /// No description provided for @pmAddCard.
  ///
  /// In es, this message translates to:
  /// **'Agregar Tarjeta'**
  String get pmAddCard;

  /// No description provided for @pmOtherMethods.
  ///
  /// In es, this message translates to:
  /// **'Otros Métodos'**
  String get pmOtherMethods;

  /// No description provided for @pmBankTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia Bancaria'**
  String get pmBankTransfer;

  /// No description provided for @pmBankTransferDesc.
  ///
  /// In es, this message translates to:
  /// **'Paga directamente desde tu banco'**
  String get pmBankTransferDesc;

  /// No description provided for @pmApplePay.
  ///
  /// In es, this message translates to:
  /// **'Apple Pay'**
  String get pmApplePay;

  /// No description provided for @pmApplePayDesc.
  ///
  /// In es, this message translates to:
  /// **'Pago rápido con tu dispositivo'**
  String get pmApplePayDesc;

  /// No description provided for @pmGooglePay.
  ///
  /// In es, this message translates to:
  /// **'Google Pay'**
  String get pmGooglePay;

  /// No description provided for @pmGooglePayDesc.
  ///
  /// In es, this message translates to:
  /// **'Paga con tu cuenta de Google'**
  String get pmGooglePayDesc;

  /// No description provided for @pmSoon.
  ///
  /// In es, this message translates to:
  /// **'Pronto'**
  String get pmSoon;

  /// No description provided for @pmSecure100.
  ///
  /// In es, this message translates to:
  /// **'Pagos 100% seguros'**
  String get pmSecure100;

  /// No description provided for @pmSecureDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus pagos son procesados por Stripe con cifrado de grado bancario. Atrio nunca almacena tus datos de tarjeta.'**
  String get pmSecureDesc;

  /// No description provided for @pmAddCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar Tarjeta'**
  String get pmAddCardTitle;

  /// No description provided for @pmAddCardDesc.
  ///
  /// In es, this message translates to:
  /// **'Tu tarjeta será procesada de forma segura por Stripe'**
  String get pmAddCardDesc;

  /// No description provided for @pmFieldCardNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de tarjeta'**
  String get pmFieldCardNumber;

  /// No description provided for @pmFieldCardHolder.
  ///
  /// In es, this message translates to:
  /// **'Nombre del titular'**
  String get pmFieldCardHolder;

  /// No description provided for @pmFieldCardHolderHint.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE APELLIDO'**
  String get pmFieldCardHolderHint;

  /// No description provided for @pmFieldExpiry.
  ///
  /// In es, this message translates to:
  /// **'MM/AA'**
  String get pmFieldExpiry;

  /// No description provided for @pmFieldCvc.
  ///
  /// In es, this message translates to:
  /// **'CVC'**
  String get pmFieldCvc;

  /// No description provided for @pmSaveWithStripe.
  ///
  /// In es, this message translates to:
  /// **'Guardar con Stripe'**
  String get pmSaveWithStripe;

  /// No description provided for @pmCardAdded.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta agregada correctamente'**
  String get pmCardAdded;

  /// No description provided for @pmProcessedByStripe.
  ///
  /// In es, this message translates to:
  /// **'Procesado de forma segura por Stripe'**
  String get pmProcessedByStripe;

  /// No description provided for @helpCenterTitle.
  ///
  /// In es, this message translates to:
  /// **'Centro de Ayuda'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterContact.
  ///
  /// In es, this message translates to:
  /// **'Contactar soporte'**
  String get helpCenterContact;

  /// No description provided for @helpCenterFaq.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get helpCenterFaq;

  /// No description provided for @hcSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el centro de ayuda...'**
  String get hcSearchHint;

  /// No description provided for @hcQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones Rápidas'**
  String get hcQuickActions;

  /// No description provided for @hcQALiveChat.
  ///
  /// In es, this message translates to:
  /// **'Chat en\nVivo'**
  String get hcQALiveChat;

  /// No description provided for @hcQAEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar\nEmail'**
  String get hcQAEmail;

  /// No description provided for @hcQACall.
  ///
  /// In es, this message translates to:
  /// **'Llamar\nSoporte'**
  String get hcQACall;

  /// No description provided for @hcCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get hcCategories;

  /// No description provided for @hcCatBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get hcCatBookings;

  /// No description provided for @hcCatPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos y Reembolsos'**
  String get hcCatPayments;

  /// No description provided for @hcCatHosts.
  ///
  /// In es, this message translates to:
  /// **'Anfitriones'**
  String get hcCatHosts;

  /// No description provided for @hcCatAccount.
  ///
  /// In es, this message translates to:
  /// **'Tu Cuenta'**
  String get hcCatAccount;

  /// No description provided for @hcCatSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad y Privacidad'**
  String get hcCatSecurity;

  /// No description provided for @hcArticlesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 artículo} other{{count} artículos}}'**
  String hcArticlesCount(int count);

  /// No description provided for @hcFaq.
  ///
  /// In es, this message translates to:
  /// **'Preguntas Frecuentes'**
  String get hcFaq;

  /// No description provided for @hcFaqCancelQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo puedo cancelar una reserva?'**
  String get hcFaqCancelQ;

  /// No description provided for @hcFaqCancelA.
  ///
  /// In es, this message translates to:
  /// **'Puedes cancelar una reserva desde la sección \"Mis Reservas\". La política de cancelación depende del anfitrión y el tipo de reserva.'**
  String get hcFaqCancelA;

  /// No description provided for @hcFaqRefundQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo recibiré mi reembolso?'**
  String get hcFaqRefundQ;

  /// No description provided for @hcFaqRefundA.
  ///
  /// In es, this message translates to:
  /// **'Los reembolsos se procesan en 5-10 días hábiles dependiendo de tu banco. Recibirás una notificación cuando el reembolso sea procesado.'**
  String get hcFaqRefundA;

  /// No description provided for @hcFaqHostQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo me convierto en anfitrión?'**
  String get hcFaqHostQ;

  /// No description provided for @hcFaqHostA.
  ///
  /// In es, this message translates to:
  /// **'Ve a tu perfil y selecciona \"Cambiar a Anfitrión\". Completa tu perfil de anfitrión y crea tu primer anuncio.'**
  String get hcFaqHostA;

  /// No description provided for @hcFaqKycQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo verifico mi identidad?'**
  String get hcFaqKycQ;

  /// No description provided for @hcFaqKycA.
  ///
  /// In es, this message translates to:
  /// **'Ve a Perfil > Verificación de identidad. Necesitarás un documento oficial con foto y una selfie. El proceso toma menos de 5 minutos.'**
  String get hcFaqKycA;

  /// No description provided for @hcFaqSafeQ.
  ///
  /// In es, this message translates to:
  /// **'¿Es seguro usar Atrio?'**
  String get hcFaqSafeQ;

  /// No description provided for @hcFaqSafeA.
  ///
  /// In es, this message translates to:
  /// **'Sí. Todos los pagos están protegidos, verificamos la identidad de los usuarios, y ofrecemos soporte 24/7. Tu información personal nunca se comparte.'**
  String get hcFaqSafeA;

  /// No description provided for @hcNeedMoreHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas más ayuda?'**
  String get hcNeedMoreHelp;

  /// No description provided for @hcSupport247.
  ///
  /// In es, this message translates to:
  /// **'Nuestro equipo de soporte está disponible 24/7'**
  String get hcSupport247;

  /// No description provided for @hcContactSupport.
  ///
  /// In es, this message translates to:
  /// **'Contactar Soporte'**
  String get hcContactSupport;

  /// No description provided for @hcComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Función disponible próximamente'**
  String get hcComingSoon;

  /// No description provided for @aboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de Atrio'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get aboutVersion;

  /// No description provided for @aboutHeader.
  ///
  /// In es, this message translates to:
  /// **'Sobre Atrio'**
  String get aboutHeader;

  /// No description provided for @aboutPremiumMarket.
  ///
  /// In es, this message translates to:
  /// **'Tu Marketplace Premium'**
  String get aboutPremiumMarket;

  /// No description provided for @aboutDescription.
  ///
  /// In es, this message translates to:
  /// **'Atrio es el marketplace premium que conecta anfitriones con usuarios a través de espacios únicos, experiencias memorables y servicios profesionales.\n\nNuestra plataforma ofrece un ecosistema completo: búsqueda inteligente, reservas en tiempo real con 3 modalidades (por horas, día completo y noches), chat directo con anfitriones, sistema de reseñas verificadas, verificación de identidad (KYC), gestión de pagos con comisiones transparentes (7%, máx \$90.000 CLP), panel de control para anfitriones con analítica de ingresos, calendario de disponibilidad interactivo, notificaciones en tiempo real, servicios rápidos bajo demanda, experiencias con cupos y horarios, sistema de niveles y logros, y resolución de disputas integrada.\n\nYa sea que busques un loft industrial para un shooting, una villa para un retiro creativo, un tour gastronómico, o un servicio de fotografía profesional, Atrio te conecta con las mejores opciones curadas por nuestra comunidad.\n\nDesarrollada con pasión en Santiago de Chile 🇨🇱'**
  String get aboutDescription;

  /// No description provided for @aboutFeatSpaces.
  ///
  /// In es, this message translates to:
  /// **'Espacios'**
  String get aboutFeatSpaces;

  /// No description provided for @aboutFeatSpacesDesc.
  ///
  /// In es, this message translates to:
  /// **'Lofts, villas, estudios y rooftops'**
  String get aboutFeatSpacesDesc;

  /// No description provided for @aboutFeatExperiences.
  ///
  /// In es, this message translates to:
  /// **'Experiencias'**
  String get aboutFeatExperiences;

  /// No description provided for @aboutFeatExperiencesDesc.
  ///
  /// In es, this message translates to:
  /// **'Tours, talleres y eventos únicos'**
  String get aboutFeatExperiencesDesc;

  /// No description provided for @aboutFeatServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get aboutFeatServices;

  /// No description provided for @aboutFeatServicesDesc.
  ///
  /// In es, this message translates to:
  /// **'Fotografía, catering, limpieza y más'**
  String get aboutFeatServicesDesc;

  /// No description provided for @aboutFeatChat.
  ///
  /// In es, this message translates to:
  /// **'Chat en Tiempo Real'**
  String get aboutFeatChat;

  /// No description provided for @aboutFeatChatDesc.
  ///
  /// In es, this message translates to:
  /// **'Comunícate directo con anfitriones'**
  String get aboutFeatChatDesc;

  /// No description provided for @aboutFeatKyc.
  ///
  /// In es, this message translates to:
  /// **'Verificación KYC'**
  String get aboutFeatKyc;

  /// No description provided for @aboutFeatKycDesc.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada para mayor confianza'**
  String get aboutFeatKycDesc;

  /// No description provided for @aboutFeatNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get aboutFeatNotifications;

  /// No description provided for @aboutFeatNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Actualizaciones en tiempo real'**
  String get aboutFeatNotificationsDesc;

  /// No description provided for @aboutStatCommission.
  ///
  /// In es, this message translates to:
  /// **'Comisión estándar'**
  String get aboutStatCommission;

  /// No description provided for @aboutStatMaxFee.
  ///
  /// In es, this message translates to:
  /// **'Fee máximo'**
  String get aboutStatMaxFee;

  /// No description provided for @aboutStatSupport.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get aboutStatSupport;

  /// No description provided for @aboutLinkTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones'**
  String get aboutLinkTerms;

  /// No description provided for @aboutLinkPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get aboutLinkPrivacy;

  /// No description provided for @aboutLinkLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias de Software'**
  String get aboutLinkLicenses;

  /// No description provided for @aboutLinkShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir Atrio'**
  String get aboutLinkShare;

  /// No description provided for @aboutShareText.
  ///
  /// In es, this message translates to:
  /// **'¡Descubre Atrio! El marketplace de espacios, experiencias y servicios premium. Descárgala ahora.'**
  String get aboutShareText;

  /// No description provided for @aboutCopyright.
  ///
  /// In es, this message translates to:
  /// **'© 2026 Atrio Technologies SpA. Santiago de Chile.'**
  String get aboutCopyright;

  /// No description provided for @privacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyTitle;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In es, this message translates to:
  /// **'Última actualización: 1 de marzo de 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyS1Title.
  ///
  /// In es, this message translates to:
  /// **'1. Información que Recopilamos'**
  String get privacyS1Title;

  /// No description provided for @privacyS1Body.
  ///
  /// In es, this message translates to:
  /// **'En Atrio recopilamos diferentes tipos de información para proporcionar y mejorar nuestros servicios:\n\n• Información de registro: nombre, correo electrónico, número de teléfono y foto de perfil.\n\n• Información de verificación: documentos de identidad para la verificación de anfitriones (KYC).\n\n• Datos de uso: interacciones con la aplicación, búsquedas, reservas, mensajes enviados y preferencias.\n\n• Información de dispositivo: modelo, sistema operativo, identificadores únicos y datos de red.\n\n• Datos de ubicación: con su consentimiento, para mostrar resultados relevantes cerca de usted.'**
  String get privacyS1Body;

  /// No description provided for @privacyS2Title.
  ///
  /// In es, this message translates to:
  /// **'2. Uso de la Información'**
  String get privacyS2Title;

  /// No description provided for @privacyS2Body.
  ///
  /// In es, this message translates to:
  /// **'Utilizamos su información personal para:\n\n• Facilitar la creación y gestión de su cuenta\n• Procesar reservas y transacciones de pago\n• Conectar usuarios con anfitriones de manera eficiente\n• Enviar notificaciones relevantes sobre reservas y mensajes\n• Mejorar y personalizar su experiencia en la plataforma\n• Prevenir fraudes y garantizar la seguridad de la comunidad\n• Cumplir con obligaciones legales y regulatorias\n• Generar análisis estadísticos anónimos para mejorar el servicio'**
  String get privacyS2Body;

  /// No description provided for @privacyS3Title.
  ///
  /// In es, this message translates to:
  /// **'3. Compartir Información'**
  String get privacyS3Title;

  /// No description provided for @privacyS3Body.
  ///
  /// In es, this message translates to:
  /// **'Atrio no vende su información personal a terceros. Podemos compartir información limitada en los siguientes casos:\n\n• Con otros usuarios: cuando realiza o recibe una reserva, compartimos la información necesaria para completar la transacción (nombre, foto, datos de contacto).\n\n• Proveedores de servicios: procesadores de pago, servicios de almacenamiento en la nube y herramientas de análisis que nos ayudan a operar la plataforma.\n\n• Requisitos legales: cuando sea necesario para cumplir con la ley, procesos legales o solicitudes gubernamentales.'**
  String get privacyS3Body;

  /// No description provided for @privacyS4Title.
  ///
  /// In es, this message translates to:
  /// **'4. Almacenamiento y Seguridad'**
  String get privacyS4Title;

  /// No description provided for @privacyS4Body.
  ///
  /// In es, this message translates to:
  /// **'Su información se almacena en servidores seguros con cifrado de extremo a extremo. Implementamos medidas de seguridad técnicas y organizativas para proteger sus datos contra acceso no autorizado, alteración, divulgación o destrucción. Los datos de pago se procesan a través de proveedores certificados PCI DSS y nunca se almacenan en nuestros servidores.'**
  String get privacyS4Body;

  /// No description provided for @privacyS5Title.
  ///
  /// In es, this message translates to:
  /// **'5. Retención de Datos'**
  String get privacyS5Title;

  /// No description provided for @privacyS5Body.
  ///
  /// In es, this message translates to:
  /// **'Conservamos su información personal mientras su cuenta esté activa o según sea necesario para proporcionarle servicios. Si solicita la eliminación de su cuenta, eliminaremos o anonimizaremos su información personal dentro de los 30 días siguientes, excepto cuando estemos obligados por ley a retener ciertos datos por un período específico.'**
  String get privacyS5Body;

  /// No description provided for @privacyS6Title.
  ///
  /// In es, this message translates to:
  /// **'6. Sus Derechos'**
  String get privacyS6Title;

  /// No description provided for @privacyS6Body.
  ///
  /// In es, this message translates to:
  /// **'Usted tiene derecho a:\n\n• Acceder a sus datos personales almacenados en nuestra plataforma\n• Rectificar información inexacta o desactualizada\n• Solicitar la eliminación de sus datos personales\n• Oponerse al procesamiento de sus datos para fines específicos\n• Solicitar la portabilidad de sus datos en formato estructurado\n• Retirar su consentimiento en cualquier momento\n\nPara ejercer estos derechos, contáctenos a través de privacy@atriocompany.cloud'**
  String get privacyS6Body;

  /// No description provided for @privacyS7Title.
  ///
  /// In es, this message translates to:
  /// **'7. Cookies y Tecnologías Similares'**
  String get privacyS7Title;

  /// No description provided for @privacyS7Body.
  ///
  /// In es, this message translates to:
  /// **'Utilizamos cookies y tecnologías similares para mejorar su experiencia, recordar sus preferencias y analizar el uso de la plataforma. Puede configurar su dispositivo para rechazar cookies, aunque esto podría afectar ciertas funcionalidades de la aplicación.'**
  String get privacyS7Body;

  /// No description provided for @privacyS8Title.
  ///
  /// In es, this message translates to:
  /// **'8. Menores de Edad'**
  String get privacyS8Title;

  /// No description provided for @privacyS8Body.
  ///
  /// In es, this message translates to:
  /// **'Atrio no está dirigido a menores de 18 años. No recopilamos conscientemente información personal de menores de edad. Si descubrimos que hemos recopilado información de un menor, tomaremos medidas para eliminar dicha información de nuestros registros.'**
  String get privacyS8Body;

  /// No description provided for @privacyS9Title.
  ///
  /// In es, this message translates to:
  /// **'9. Cambios en esta Política'**
  String get privacyS9Title;

  /// No description provided for @privacyS9Body.
  ///
  /// In es, this message translates to:
  /// **'Podemos actualizar esta política de privacidad periódicamente para reflejar cambios en nuestras prácticas de información. Le notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico. Le recomendamos revisar esta política regularmente.'**
  String get privacyS9Body;

  /// No description provided for @privacyS10Title.
  ///
  /// In es, this message translates to:
  /// **'10. Contacto'**
  String get privacyS10Title;

  /// No description provided for @privacyS10Body.
  ///
  /// In es, this message translates to:
  /// **'Si tiene preguntas sobre esta política de privacidad o sobre cómo manejamos su información personal, puede contactarnos:\n\n• Email: privacy@atriocompany.cloud\n• Centro de Ayuda dentro de la aplicación\n• Responsable de Protección de Datos: dpo@atriocompany.cloud'**
  String get privacyS10Body;

  /// No description provided for @termsTitle.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones'**
  String get termsTitle;

  /// No description provided for @termsHeader.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones de Uso'**
  String get termsHeader;

  /// No description provided for @termsLastUpdated.
  ///
  /// In es, this message translates to:
  /// **'Última actualización: 1 de marzo de 2026'**
  String get termsLastUpdated;

  /// No description provided for @termsS1Title.
  ///
  /// In es, this message translates to:
  /// **'1. Aceptación de los Términos'**
  String get termsS1Title;

  /// No description provided for @termsS1Body.
  ///
  /// In es, this message translates to:
  /// **'Al acceder y utilizar la aplicación Atrio (\"la Plataforma\"), usted acepta estar vinculado por estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no podrá acceder ni utilizar nuestros servicios. Estos términos constituyen un acuerdo legalmente vinculante entre usted y Atrio Technologies SpA'**
  String get termsS1Body;

  /// No description provided for @termsS2Title.
  ///
  /// In es, this message translates to:
  /// **'2. Descripción del Servicio'**
  String get termsS2Title;

  /// No description provided for @termsS2Body.
  ///
  /// In es, this message translates to:
  /// **'Atrio es una plataforma de marketplace premium que conecta a anfitriones con usuarios, facilitando la reserva de espacios, experiencias y servicios profesionales. La Plataforma actúa como intermediario entre las partes, proporcionando las herramientas tecnológicas necesarias para que los usuarios publiquen, descubran y reserven ofertas.'**
  String get termsS2Body;

  /// No description provided for @termsS3Title.
  ///
  /// In es, this message translates to:
  /// **'3. Registro y Cuentas de Usuario'**
  String get termsS3Title;

  /// No description provided for @termsS3Body.
  ///
  /// In es, this message translates to:
  /// **'Para utilizar ciertos servicios de Atrio, debe crear una cuenta proporcionando información precisa y completa. Usted es responsable de mantener la confidencialidad de sus credenciales de acceso y de todas las actividades que ocurran bajo su cuenta. Debe notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta o cualquier violación de seguridad.'**
  String get termsS3Body;

  /// No description provided for @termsS4Title.
  ///
  /// In es, this message translates to:
  /// **'4. Roles de Usuario'**
  String get termsS4Title;

  /// No description provided for @termsS4Body.
  ///
  /// In es, this message translates to:
  /// **'Los usuarios pueden operar en dos modalidades dentro de Atrio:\n\n• Modo Usuario: Permite explorar, buscar y reservar espacios, experiencias y servicios publicados por los anfitriones.\n\n• Modo Anfitrión: Permite publicar y gestionar espacios, experiencias y servicios, recibir reservas y administrar ingresos a través del panel de control.'**
  String get termsS4Body;

  /// No description provided for @termsS5Title.
  ///
  /// In es, this message translates to:
  /// **'5. Reservas y Pagos'**
  String get termsS5Title;

  /// No description provided for @termsS5Body.
  ///
  /// In es, this message translates to:
  /// **'Todas las transacciones se procesan a través de nuestros proveedores de pago autorizados. Atrio cobra una comisión de servicio sobre cada transacción completada. Las tarifas, comisiones y cargos adicionales se mostrarán de forma transparente antes de confirmar cualquier reserva. Los anfitriones recibirán sus pagos según el calendario de desembolsos establecido.'**
  String get termsS5Body;

  /// No description provided for @termsS6Title.
  ///
  /// In es, this message translates to:
  /// **'6. Cancelaciones y Reembolsos'**
  String get termsS6Title;

  /// No description provided for @termsS6Body.
  ///
  /// In es, this message translates to:
  /// **'Las políticas de cancelación varían según el tipo de reserva y las condiciones establecidas por cada anfitrión. Los usuarios podrán cancelar reservas según la política aplicable. Los reembolsos se procesarán dentro de los 5-10 días hábiles siguientes a la aprobación de la cancelación, utilizando el mismo método de pago original.'**
  String get termsS6Body;

  /// No description provided for @termsS7Title.
  ///
  /// In es, this message translates to:
  /// **'7. Conducta del Usuario'**
  String get termsS7Title;

  /// No description provided for @termsS7Body.
  ///
  /// In es, this message translates to:
  /// **'Los usuarios se comprometen a:\n\n• No utilizar la plataforma para fines ilegales o no autorizados\n• No publicar contenido falso, engañoso o fraudulento\n• Respetar los derechos de propiedad intelectual de terceros\n• Mantener una conducta respetuosa en todas las interacciones\n• No intentar eludir las medidas de seguridad de la plataforma\n• No manipular reseñas o calificaciones'**
  String get termsS7Body;

  /// No description provided for @termsS8Title.
  ///
  /// In es, this message translates to:
  /// **'8. Propiedad Intelectual'**
  String get termsS8Title;

  /// No description provided for @termsS8Body.
  ///
  /// In es, this message translates to:
  /// **'Todo el contenido de Atrio, incluyendo pero no limitado a textos, gráficos, logotipos, iconos, imágenes, clips de audio, descargas digitales y compilaciones de datos, es propiedad de Atrio Technologies SpA o de sus proveedores de contenido y está protegido por las leyes de propiedad intelectual aplicables.'**
  String get termsS8Body;

  /// No description provided for @termsS9Title.
  ///
  /// In es, this message translates to:
  /// **'9. Limitación de Responsabilidad'**
  String get termsS9Title;

  /// No description provided for @termsS9Body.
  ///
  /// In es, this message translates to:
  /// **'Atrio actúa como intermediario y no es responsable de las acciones, conductas o contenidos de los usuarios. No garantizamos la calidad, seguridad o legalidad de los espacios, experiencias o servicios publicados. Los usuarios asumen toda responsabilidad por sus interacciones y transacciones realizadas a través de la plataforma.'**
  String get termsS9Body;

  /// No description provided for @termsS10Title.
  ///
  /// In es, this message translates to:
  /// **'10. Modificaciones'**
  String get termsS10Title;

  /// No description provided for @termsS10Body.
  ///
  /// In es, this message translates to:
  /// **'Atrio se reserva el derecho de modificar estos términos en cualquier momento. Las modificaciones entrarán en vigor a partir de su publicación en la plataforma. El uso continuado de la aplicación después de cualquier modificación constituye su aceptación de los nuevos términos.'**
  String get termsS10Body;

  /// No description provided for @termsS11Title.
  ///
  /// In es, this message translates to:
  /// **'11. Contacto'**
  String get termsS11Title;

  /// No description provided for @termsS11Body.
  ///
  /// In es, this message translates to:
  /// **'Para consultas sobre estos términos, puede contactarnos a través de:\n\n• Email: legal@atriocompany.cloud\n• Centro de Ayuda dentro de la aplicación\n• Dirección: Atrio Technologies SpA, Santiago de Chile, Chile'**
  String get termsS11Body;

  /// No description provided for @kycTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación de Identidad'**
  String get kycTitle;

  /// No description provided for @kycSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu identidad para acceder a todas las funciones'**
  String get kycSubtitle;

  /// No description provided for @kycUploadId.
  ///
  /// In es, this message translates to:
  /// **'Subir documento'**
  String get kycUploadId;

  /// No description provided for @kycSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar verificación'**
  String get kycSubmit;

  /// No description provided for @kycPending.
  ///
  /// In es, this message translates to:
  /// **'Verificación pendiente'**
  String get kycPending;

  /// No description provided for @kycApproved.
  ///
  /// In es, this message translates to:
  /// **'Verificación aprobada'**
  String get kycApproved;

  /// No description provided for @kycStatusComplete.
  ///
  /// In es, this message translates to:
  /// **'Verificación Completa'**
  String get kycStatusComplete;

  /// No description provided for @kycStatusUnverified.
  ///
  /// In es, this message translates to:
  /// **'Sin Verificar'**
  String get kycStatusUnverified;

  /// No description provided for @kycStatusPartial.
  ///
  /// In es, this message translates to:
  /// **'Verificación Parcial'**
  String get kycStatusPartial;

  /// No description provided for @kycStepsProgress.
  ///
  /// In es, this message translates to:
  /// **'{count} de 4 pasos completados'**
  String kycStepsProgress(int count);

  /// No description provided for @kycWhyVerify.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué verificarte?'**
  String get kycWhyVerify;

  /// No description provided for @kycBenefit1.
  ///
  /// In es, this message translates to:
  /// **'Mayor confianza de anfitriones y usuarios'**
  String get kycBenefit1;

  /// No description provided for @kycBenefit2.
  ///
  /// In es, this message translates to:
  /// **'Reservas aprobadas más rápido'**
  String get kycBenefit2;

  /// No description provided for @kycBenefit3.
  ///
  /// In es, this message translates to:
  /// **'Acceso a espacios exclusivos'**
  String get kycBenefit3;

  /// No description provided for @kycBenefit4.
  ///
  /// In es, this message translates to:
  /// **'Protección de tu identidad'**
  String get kycBenefit4;

  /// No description provided for @kycStepsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pasos de Verificación'**
  String get kycStepsTitle;

  /// No description provided for @kycStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Verificar Email'**
  String get kycStep1Title;

  /// No description provided for @kycStep1Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu email ha sido confirmado'**
  String get kycStep1Subtitle;

  /// No description provided for @kycStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Verificar Teléfono'**
  String get kycStep2Title;

  /// No description provided for @kycStep2SubtitleVerified.
  ///
  /// In es, this message translates to:
  /// **'Tu número ha sido verificado'**
  String get kycStep2SubtitleVerified;

  /// No description provided for @kycStep2SubtitlePending.
  ///
  /// In es, this message translates to:
  /// **'Agrega y verifica tu número'**
  String get kycStep2SubtitlePending;

  /// No description provided for @kycStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Documento de Identidad'**
  String get kycStep3Title;

  /// No description provided for @kycStep3SubtitleSent.
  ///
  /// In es, this message translates to:
  /// **'Documento enviado'**
  String get kycStep3SubtitleSent;

  /// No description provided for @kycStep3SubtitlePending.
  ///
  /// In es, this message translates to:
  /// **'Sube tu INE, pasaporte o licencia'**
  String get kycStep3SubtitlePending;

  /// No description provided for @kycStep4Title.
  ///
  /// In es, this message translates to:
  /// **'Selfie de Verificación'**
  String get kycStep4Title;

  /// No description provided for @kycStep4SubtitleVerified.
  ///
  /// In es, this message translates to:
  /// **'Selfie verificado'**
  String get kycStep4SubtitleVerified;

  /// No description provided for @kycStep4SubtitlePending.
  ///
  /// In es, this message translates to:
  /// **'Toma una foto de tu rostro'**
  String get kycStep4SubtitlePending;

  /// No description provided for @kycSecureInfo.
  ///
  /// In es, this message translates to:
  /// **'Tu información está segura'**
  String get kycSecureInfo;

  /// No description provided for @kycSecureInfoDesc.
  ///
  /// In es, this message translates to:
  /// **'Usamos cifrado de grado bancario para proteger tus datos. Solo verificamos tu identidad, nunca compartimos tu información.'**
  String get kycSecureInfoDesc;

  /// No description provided for @kycPhoneDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar Teléfono'**
  String get kycPhoneDialogTitle;

  /// No description provided for @kycPhoneDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu número de celular para verificar tu cuenta.'**
  String get kycPhoneDialogSubtitle;

  /// No description provided for @kycPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de celular'**
  String get kycPhoneLabel;

  /// No description provided for @kycPhoneHint.
  ///
  /// In es, this message translates to:
  /// **'+56 9 1234 5678'**
  String get kycPhoneHint;

  /// No description provided for @kycInvalidPhone.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número válido (ej: +56 9 1234 5678)'**
  String get kycInvalidPhone;

  /// No description provided for @kycPhoneVerified.
  ///
  /// In es, this message translates to:
  /// **'Teléfono verificado correctamente'**
  String get kycPhoneVerified;

  /// No description provided for @kycVerifyPhoneBtn.
  ///
  /// In es, this message translates to:
  /// **'Verificar Teléfono'**
  String get kycVerifyPhoneBtn;

  /// No description provided for @kycDocUploaded.
  ///
  /// In es, this message translates to:
  /// **'Documento subido. En revisión.'**
  String get kycDocUploaded;

  /// No description provided for @kycCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Verificación completada!'**
  String get kycCompleted;

  /// No description provided for @kycDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get kycDone;

  /// No description provided for @quickServicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios Rápidos'**
  String get quickServicesTitle;

  /// No description provided for @quickServicesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Encuentra profesionales de confianza'**
  String get quickServicesSubtitle;

  /// No description provided for @publishServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Publicar Servicio'**
  String get publishServiceTitle;

  /// No description provided for @publishServicePublished.
  ///
  /// In es, this message translates to:
  /// **'Servicio publicado'**
  String get publishServicePublished;

  /// No description provided for @reviewsListTitle.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get reviewsListTitle;

  /// No description provided for @reviewsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay reseñas aún'**
  String get reviewsEmpty;

  /// No description provided for @reviewsListCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Reseñas ({count})'**
  String reviewsListCountTitle(int count);

  /// No description provided for @reviewsError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar reseñas'**
  String get reviewsError;

  /// No description provided for @reviewsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reviewsRetry;

  /// No description provided for @reviewsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay reseñas'**
  String get reviewsEmptyTitle;

  /// No description provided for @reviewsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero en dejar una reseña'**
  String get reviewsEmptySubtitle;

  /// No description provided for @reviewsDefaultUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get reviewsDefaultUser;

  /// No description provided for @timeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get timeToday;

  /// No description provided for @timeYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {d} días'**
  String timeDaysAgo(int d);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {w} sem'**
  String timeWeeksAgo(int w);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {m} meses'**
  String timeMonthsAgo(int m);

  /// No description provided for @timeYearsAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {y} años'**
  String timeYearsAgo(int y);

  /// No description provided for @writeReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribir Reseña'**
  String get writeReviewTitle;

  /// No description provided for @writeReviewRating.
  ///
  /// In es, this message translates to:
  /// **'Tu calificación'**
  String get writeReviewRating;

  /// No description provided for @writeReviewComment.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu comentario...'**
  String get writeReviewComment;

  /// No description provided for @writeReviewSubmit.
  ///
  /// In es, this message translates to:
  /// **'Publicar reseña'**
  String get writeReviewSubmit;

  /// No description provided for @writeReviewSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Reseña publicada'**
  String get writeReviewSubmitted;

  /// No description provided for @writeReviewSelectRating.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una calificación'**
  String get writeReviewSelectRating;

  /// No description provided for @writeReviewNotAuthenticated.
  ///
  /// In es, this message translates to:
  /// **'No autenticado'**
  String get writeReviewNotAuthenticated;

  /// No description provided for @writeReviewHowWasIt.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue tu experiencia?'**
  String get writeReviewHowWasIt;

  /// No description provided for @writeReviewTapToRate.
  ///
  /// In es, this message translates to:
  /// **'Toca para calificar'**
  String get writeReviewTapToRate;

  /// No description provided for @writeReviewRatingPoor.
  ///
  /// In es, this message translates to:
  /// **'Podría mejorar'**
  String get writeReviewRatingPoor;

  /// No description provided for @writeReviewRatingGood.
  ///
  /// In es, this message translates to:
  /// **'Buena'**
  String get writeReviewRatingGood;

  /// No description provided for @writeReviewRatingVeryGood.
  ///
  /// In es, this message translates to:
  /// **'¡Muy buena!'**
  String get writeReviewRatingVeryGood;

  /// No description provided for @writeReviewRatingExcellent.
  ///
  /// In es, this message translates to:
  /// **'¡Excelente!'**
  String get writeReviewRatingExcellent;

  /// No description provided for @writeReviewCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos más sobre tu experiencia (opcional)'**
  String get writeReviewCommentHint;

  /// No description provided for @writeReviewSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar Reseña'**
  String get writeReviewSubmitButton;

  /// No description provided for @writeReviewSentSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Reseña enviada!'**
  String get writeReviewSentSuccess;

  /// No description provided for @splashTagline.
  ///
  /// In es, this message translates to:
  /// **'Vive experiencias únicas'**
  String get splashTagline;

  /// No description provided for @splashCategories.
  ///
  /// In es, this message translates to:
  /// **'Espacios · Experiencias · Servicios'**
  String get splashCategories;

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet'**
  String get offlineBanner;

  /// No description provided for @offlineBannerCached.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Mostrando contenido guardado.'**
  String get offlineBannerCached;

  /// No description provided for @bookingContactHostAction.
  ///
  /// In es, this message translates to:
  /// **'Contactar Anfitrion'**
  String get bookingContactHostAction;

  /// No description provided for @bookingConfirmedAction.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get bookingConfirmedAction;

  /// No description provided for @checkoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Reserva'**
  String get checkoutConfirmTitle;

  /// No description provided for @checkoutNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontrado'**
  String get checkoutNotFound;

  /// No description provided for @checkoutLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get checkoutLoadError;

  /// No description provided for @checkoutSelectDatesFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona las fechas primero'**
  String get checkoutSelectDatesFirst;

  /// No description provided for @checkoutSelectDay.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un día'**
  String get checkoutSelectDay;

  /// No description provided for @checkoutSelectDateAndSlots.
  ///
  /// In es, this message translates to:
  /// **'Selecciona fecha y horarios'**
  String get checkoutSelectDateAndSlots;

  /// No description provided for @checkoutCalcError.
  ///
  /// In es, this message translates to:
  /// **'Error en el calculo. Recarga e intenta de nuevo.'**
  String get checkoutCalcError;

  /// No description provided for @checkoutDatesUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Las fechas seleccionadas ya no estan disponibles'**
  String get checkoutDatesUnavailable;

  /// No description provided for @checkoutDevMode.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada (modo desarrollo)'**
  String get checkoutDevMode;

  /// No description provided for @checkoutPaymentPending.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente. Puedes pagar desde \"Mis Reservas\".'**
  String get checkoutPaymentPending;

  /// No description provided for @checkoutPaymentApproved.
  ///
  /// In es, this message translates to:
  /// **'Pago aprobado'**
  String get checkoutPaymentApproved;

  /// No description provided for @checkoutPaymentNotApproved.
  ///
  /// In es, this message translates to:
  /// **'El pago no fue aprobado: {reason}'**
  String checkoutPaymentNotApproved(String reason);

  /// No description provided for @checkoutPaymentInProcess.
  ///
  /// In es, this message translates to:
  /// **'Pago en proceso. Te notificaremos cuando se confirme.'**
  String get checkoutPaymentInProcess;

  /// No description provided for @checkoutPaymentRejected.
  ///
  /// In es, this message translates to:
  /// **'El pago fue rechazado.'**
  String get checkoutPaymentRejected;

  /// No description provided for @checkoutPaymentError.
  ///
  /// In es, this message translates to:
  /// **'Error de pago: {message}'**
  String checkoutPaymentError(String message);

  /// No description provided for @checkoutRejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago rechazado'**
  String get checkoutRejectedTitle;

  /// No description provided for @checkoutRejectedDesc.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva esta guardada pero el pago no se completo. Puedes reintentar o pagar mas tarde desde \"Mis Reservas\".'**
  String get checkoutRejectedDesc;

  /// No description provided for @checkoutGoToBookings.
  ///
  /// In es, this message translates to:
  /// **'Ir a Reservas'**
  String get checkoutGoToBookings;

  /// No description provided for @checkoutRetryBtn.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get checkoutRetryBtn;

  /// No description provided for @checkoutSelectPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get checkoutSelectPlaceholder;

  /// No description provided for @checkoutDatesLabel.
  ///
  /// In es, this message translates to:
  /// **'Fechas'**
  String get checkoutDatesLabel;

  /// No description provided for @checkoutSelectDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un día'**
  String get checkoutSelectDayLabel;

  /// No description provided for @checkoutSelectDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona fecha'**
  String get checkoutSelectDateLabel;

  /// No description provided for @checkoutSelectOneSlot.
  ///
  /// In es, this message translates to:
  /// **'Selecciona 1 horario (precio por persona)'**
  String get checkoutSelectOneSlot;

  /// No description provided for @checkoutGuests.
  ///
  /// In es, this message translates to:
  /// **'Huéspedes'**
  String get checkoutGuests;

  /// No description provided for @checkoutPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get checkoutPeople;

  /// No description provided for @checkoutMax.
  ///
  /// In es, this message translates to:
  /// **'máx {count}'**
  String checkoutMax(int count);

  /// No description provided for @checkoutPriceSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Precio'**
  String get checkoutPriceSummary;

  /// No description provided for @checkoutCleaning.
  ///
  /// In es, this message translates to:
  /// **'Limpieza'**
  String get checkoutCleaning;

  /// No description provided for @checkoutPromoFeeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tarifa promo ({percent}) 🎉'**
  String checkoutPromoFeeLabel(String percent);

  /// No description provided for @checkoutServiceFeeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tarifa de servicio ({percent})'**
  String checkoutServiceFeeLabel(String percent);

  /// No description provided for @checkoutServiceFeeCapped.
  ///
  /// In es, this message translates to:
  /// **'Tarifa de servicio ({percent}, máx \$90.000)'**
  String checkoutServiceFeeCapped(String percent);

  /// No description provided for @checkoutPromoRemaining.
  ///
  /// In es, this message translates to:
  /// **'Tarifa promocional 1% — {count} reservas restantes'**
  String checkoutPromoRemaining(int count);

  /// No description provided for @checkoutPaymentMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Metodo de Pago'**
  String get checkoutPaymentMethodTitle;

  /// No description provided for @checkoutPaySecureBadge.
  ///
  /// In es, this message translates to:
  /// **'PAGO SEGURO POR MERCADO PAGO'**
  String get checkoutPaySecureBadge;

  /// No description provided for @checkoutPayAmount.
  ///
  /// In es, this message translates to:
  /// **'Pagar {amount}'**
  String checkoutPayAmount(String amount);

  /// No description provided for @checkoutModeHoursBlock.
  ///
  /// In es, this message translates to:
  /// **'Bloques de {hours} horas'**
  String checkoutModeHoursBlock(int hours);

  /// No description provided for @checkoutModeHours.
  ///
  /// In es, this message translates to:
  /// **'Reserva por horas'**
  String get checkoutModeHours;

  /// No description provided for @checkoutModeFullDay.
  ///
  /// In es, this message translates to:
  /// **'Día completo'**
  String get checkoutModeFullDay;

  /// No description provided for @checkoutModeNights.
  ///
  /// In es, this message translates to:
  /// **'Reserva por noches'**
  String get checkoutModeNights;

  /// No description provided for @checkoutOneDay.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get checkoutOneDay;

  /// No description provided for @checkoutNights.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 noche} other{{count} noches}}'**
  String checkoutNights(int count);

  /// No description provided for @checkoutHoursWithBlocks.
  ///
  /// In es, this message translates to:
  /// **'{hours} hora{hoursPlural} ({blocks} bloque{blocksPlural})'**
  String checkoutHoursWithBlocks(
    int hours,
    String hoursPlural,
    int blocks,
    String blocksPlural,
  );

  /// No description provided for @checkoutUnitNight.
  ///
  /// In es, this message translates to:
  /// **'noche'**
  String get checkoutUnitNight;

  /// No description provided for @checkoutUnitHour.
  ///
  /// In es, this message translates to:
  /// **'hora'**
  String get checkoutUnitHour;

  /// No description provided for @checkoutUnitSession.
  ///
  /// In es, this message translates to:
  /// **'sesión'**
  String get checkoutUnitSession;

  /// No description provided for @checkoutUnitPerson.
  ///
  /// In es, this message translates to:
  /// **'persona'**
  String get checkoutUnitPerson;

  /// No description provided for @checkoutGuestsCountSpaces.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 huésped} other{{count} huéspedes}}'**
  String checkoutGuestsCountSpaces(int count);

  /// No description provided for @checkoutGuestsCountPeople.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 persona} other{{count} personas}}'**
  String checkoutGuestsCountPeople(int count);

  /// No description provided for @checkoutPolicyStrictTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelación estricta'**
  String get checkoutPolicyStrictTitle;

  /// No description provided for @checkoutPolicyStrictDesc.
  ///
  /// In es, this message translates to:
  /// **'Reembolso del 50% hasta 7 días antes. Sin reembolso después.'**
  String get checkoutPolicyStrictDesc;

  /// No description provided for @checkoutPolicyModerateTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelación moderada'**
  String get checkoutPolicyModerateTitle;

  /// No description provided for @checkoutPolicyModerateDesc.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 5 días antes. Después se cobra el 50%.'**
  String get checkoutPolicyModerateDesc;

  /// No description provided for @checkoutPolicyFlexibleTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelación flexible'**
  String get checkoutPolicyFlexibleTitle;

  /// No description provided for @checkoutPolicyFlexibleDesc.
  ///
  /// In es, this message translates to:
  /// **'Cancelación gratuita hasta 24 horas antes del check-in. Después se cobra el 50%.'**
  String get checkoutPolicyFlexibleDesc;

  /// No description provided for @checkoutCheckInLabel.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get checkoutCheckInLabel;

  /// No description provided for @checkoutCheckOutLabel.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get checkoutCheckOutLabel;

  /// No description provided for @checkoutSandboxMode.
  ///
  /// In es, this message translates to:
  /// **'Modo prueba (sandbox)'**
  String get checkoutSandboxMode;

  /// No description provided for @checkoutMpMethods.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta, debito, transferencia'**
  String get checkoutMpMethods;

  /// No description provided for @checkoutPriceBaseMultiSlots.
  ///
  /// In es, this message translates to:
  /// **'{price} x {guests} persona{guestsPlural} x {blocks} bloque{blocksPlural}'**
  String checkoutPriceBaseMultiSlots(
    String price,
    int guests,
    String guestsPlural,
    int blocks,
    String blocksPlural,
  );

  /// No description provided for @checkoutPriceBasePerPerson.
  ///
  /// In es, this message translates to:
  /// **'{price} x {guests} persona{guestsPlural}'**
  String checkoutPriceBasePerPerson(
    String price,
    int guests,
    String guestsPlural,
  );

  /// No description provided for @checkoutPriceBaseHours.
  ///
  /// In es, this message translates to:
  /// **'{price} x {blocks} bloque{blocksPlural} ({hours}h c/u)'**
  String checkoutPriceBaseHours(
    String price,
    int blocks,
    String blocksPlural,
    int hours,
  );

  /// No description provided for @checkoutPriceBaseUnit.
  ///
  /// In es, this message translates to:
  /// **'{price} x {suffix}'**
  String checkoutPriceBaseUnit(String price, String suffix);

  /// No description provided for @checkoutNightsBadge.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 noche} other{{count} noches}}'**
  String checkoutNightsBadge(int count);

  /// No description provided for @checkoutUnitHoursBlocks.
  ///
  /// In es, this message translates to:
  /// **'{hours, plural, one{1 hora} other{{hours} horas}} ({blocks, plural, one{1 bloque} other{{blocks} bloques}})'**
  String checkoutUnitHoursBlocks(int hours, int blocks);

  /// No description provided for @checkoutUnitOneDay.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get checkoutUnitOneDay;

  /// No description provided for @checkoutPriceBasePerson.
  ///
  /// In es, this message translates to:
  /// **'{price} x {guests, plural, one{1 persona} other{{guests} personas}}'**
  String checkoutPriceBasePerson(String price, int guests);

  /// No description provided for @checkoutPriceBasePersonHours.
  ///
  /// In es, this message translates to:
  /// **'{price} x {guests, plural, one{1 persona} other{{guests} personas}} x {blocks, plural, one{1 bloque} other{{blocks} bloques}}'**
  String checkoutPriceBasePersonHours(String price, int guests, int blocks);

  /// No description provided for @checkoutPriceBaseHoursSimple.
  ///
  /// In es, this message translates to:
  /// **'{price} x {blocks, plural, one{1 bloque} other{{blocks} bloques}} ({hours}h c/u)'**
  String checkoutPriceBaseHoursSimple(String price, int blocks, int hours);

  /// No description provided for @checkoutHostFallback.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get checkoutHostFallback;

  /// No description provided for @checkoutHostLabel.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get checkoutHostLabel;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Reserva Confirmada!'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingConfirmedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud ha sido enviada al anfitrión.\nTe notificaremos cuando sea confirmada.'**
  String get bookingConfirmedSubtitle;

  /// No description provided for @bookingConfirmedNotifTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get bookingConfirmedNotifTitle;

  /// No description provided for @bookingConfirmedNotifSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibirás un aviso'**
  String get bookingConfirmedNotifSubtitle;

  /// No description provided for @bookingConfirmedGoHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al Inicio'**
  String get bookingConfirmedGoHome;

  /// No description provided for @paymentCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pago'**
  String get paymentCancelTitle;

  /// No description provided for @paymentCancelDesc.
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, tu reserva quedara pendiente de pago. Puedes reintentar el pago desde tus reservas.'**
  String get paymentCancelDesc;

  /// No description provided for @paymentKeepPaying.
  ///
  /// In es, this message translates to:
  /// **'Seguir pagando'**
  String get paymentKeepPaying;

  /// No description provided for @paymentExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get paymentExit;

  /// No description provided for @paymentSecure.
  ///
  /// In es, this message translates to:
  /// **'Pago Seguro'**
  String get paymentSecure;

  /// No description provided for @paymentLoadingCheckout.
  ///
  /// In es, this message translates to:
  /// **'Cargando checkout seguro...'**
  String get paymentLoadingCheckout;

  /// No description provided for @chatBackEditHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu mensaje...'**
  String get chatBackEditHint;

  /// No description provided for @disputesFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get disputesFilterAll;

  /// No description provided for @disputesFilterOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertas'**
  String get disputesFilterOpen;

  /// No description provided for @disputesFilterReview.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get disputesFilterReview;

  /// No description provided for @disputesFilterClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get disputesFilterClosed;

  /// No description provided for @disputesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin disputas'**
  String get disputesEmptyTitle;

  /// No description provided for @disputesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes disputas abiertas.\nTodo está en orden.'**
  String get disputesEmptySubtitle;

  /// No description provided for @disputesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar disputas'**
  String get disputesLoadError;

  /// No description provided for @disputesComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente: Crear nueva disputa'**
  String get disputesComingSoon;

  /// No description provided for @disputesStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get disputesStatusOpen;

  /// No description provided for @disputesStatusReview.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get disputesStatusReview;

  /// No description provided for @disputesStatusResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelta'**
  String get disputesStatusResolved;

  /// No description provided for @disputesStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get disputesStatusClosed;

  /// No description provided for @disputesPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get disputesPriorityHigh;

  /// No description provided for @disputesPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get disputesPriorityMedium;

  /// No description provided for @disputesPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get disputesPriorityLow;

  /// No description provided for @disputeLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get disputeLoadError;

  /// No description provided for @disputeNotFound.
  ///
  /// In es, this message translates to:
  /// **'Disputa no encontrada'**
  String get disputeNotFound;

  /// No description provided for @disputeGuest.
  ///
  /// In es, this message translates to:
  /// **'Huésped'**
  String get disputeGuest;

  /// No description provided for @disputeHost.
  ///
  /// In es, this message translates to:
  /// **'Anfitrión'**
  String get disputeHost;

  /// No description provided for @disputeHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'DISPUTA #{id}'**
  String disputeHeaderTitle(String id);

  /// No description provided for @disputeAmountAtStake.
  ///
  /// In es, this message translates to:
  /// **'{amount} en juego'**
  String disputeAmountAtStake(String amount);

  /// No description provided for @disputeTimeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get disputeTimeNow;

  /// No description provided for @disputeTimeMin.
  ///
  /// In es, this message translates to:
  /// **'Hace {min} min'**
  String disputeTimeMin(int min);

  /// No description provided for @disputeTimeHour.
  ///
  /// In es, this message translates to:
  /// **'Hace {h}h'**
  String disputeTimeHour(int h);

  /// No description provided for @disputeTimeDay.
  ///
  /// In es, this message translates to:
  /// **'Hace {d}d'**
  String disputeTimeDay(int d);

  /// No description provided for @disputeProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get disputeProgress;

  /// No description provided for @disputeStepOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get disputeStepOpen;

  /// No description provided for @disputeStepReview.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get disputeStepReview;

  /// No description provided for @disputeStepResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelta'**
  String get disputeStepResolved;

  /// No description provided for @disputeStepClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get disputeStepClosed;

  /// No description provided for @disputeTimestamps.
  ///
  /// In es, this message translates to:
  /// **'Creada: {created} • Actualizada: {updated}'**
  String disputeTimestamps(String created, String updated);

  /// No description provided for @disputeEvidenceTitle.
  ///
  /// In es, this message translates to:
  /// **'EVIDENCIA PRESENTADA'**
  String get disputeEvidenceTitle;

  /// No description provided for @disputeHostDefenseTitle.
  ///
  /// In es, this message translates to:
  /// **'DEFENSA DEL ANFITRIÓN'**
  String get disputeHostDefenseTitle;

  /// No description provided for @disputeNoDefenseYet.
  ///
  /// In es, this message translates to:
  /// **'El anfitrión no ha presentado defensa aún.'**
  String get disputeNoDefenseYet;

  /// No description provided for @disputeYourDefense.
  ///
  /// In es, this message translates to:
  /// **'Tu defensa'**
  String get disputeYourDefense;

  /// No description provided for @disputeExplainFacts.
  ///
  /// In es, this message translates to:
  /// **'Explica tu versión de los hechos'**
  String get disputeExplainFacts;

  /// No description provided for @disputeDefenseHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu defensa aquí...'**
  String get disputeDefenseHint;

  /// No description provided for @disputeSendDefense.
  ///
  /// In es, this message translates to:
  /// **'Enviar Defensa'**
  String get disputeSendDefense;

  /// No description provided for @disputeDefenseSent.
  ///
  /// In es, this message translates to:
  /// **'Defensa enviada correctamente'**
  String get disputeDefenseSent;

  /// No description provided for @disputeAddEvidence.
  ///
  /// In es, this message translates to:
  /// **'Agregar evidencia'**
  String get disputeAddEvidence;

  /// No description provided for @disputeUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo...'**
  String get disputeUploading;

  /// No description provided for @disputeEvidenceAdded.
  ///
  /// In es, this message translates to:
  /// **'Evidencia agregada'**
  String get disputeEvidenceAdded;

  /// No description provided for @disputeResolutionTitle.
  ///
  /// In es, this message translates to:
  /// **'Acción de Resolución'**
  String get disputeResolutionTitle;

  /// No description provided for @disputeResolutionFullRefund.
  ///
  /// In es, this message translates to:
  /// **'Reembolso Completo al Huésped'**
  String get disputeResolutionFullRefund;

  /// No description provided for @disputeResolutionReleasePayment.
  ///
  /// In es, this message translates to:
  /// **'Liberar Pago al Anfitrión'**
  String get disputeResolutionReleasePayment;

  /// No description provided for @disputeResolutionPartial.
  ///
  /// In es, this message translates to:
  /// **'Reembolso Parcial'**
  String get disputeResolutionPartial;

  /// No description provided for @disputeResolutionFinal.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es final y activará pagos automáticos.'**
  String get disputeResolutionFinal;

  /// No description provided for @disputeConfirmResolution.
  ///
  /// In es, this message translates to:
  /// **'Confirmar {action}'**
  String disputeConfirmResolution(String action);

  /// No description provided for @disputeResolutionConfirmDesc.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de aplicar esta resolución? Esta acción no se puede deshacer.'**
  String get disputeResolutionConfirmDesc;

  /// No description provided for @disputeResolutionApplied.
  ///
  /// In es, this message translates to:
  /// **'Resolución aplicada: {action}'**
  String disputeResolutionApplied(String action);

  /// No description provided for @disputeResolutionLabelFullRefund.
  ///
  /// In es, this message translates to:
  /// **'Reembolso Completo'**
  String get disputeResolutionLabelFullRefund;

  /// No description provided for @disputeResolutionLabelRelease.
  ///
  /// In es, this message translates to:
  /// **'Liberar Pago'**
  String get disputeResolutionLabelRelease;

  /// No description provided for @disputeResolutionLabelPartial.
  ///
  /// In es, this message translates to:
  /// **'Reembolso Parcial'**
  String get disputeResolutionLabelPartial;

  /// No description provided for @disputeTabReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte'**
  String get disputeTabReport;

  /// No description provided for @disputeTabDefense.
  ///
  /// In es, this message translates to:
  /// **'Defensa'**
  String get disputeTabDefense;

  /// No description provided for @disputePriorityLabel.
  ///
  /// In es, this message translates to:
  /// **'{priority} Prioridad'**
  String disputePriorityLabel(String priority);

  /// No description provided for @qsTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios Rápidos'**
  String get qsTitle;

  /// No description provided for @qsPublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get qsPublish;

  /// No description provided for @qsTabAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get qsTabAvailable;

  /// No description provided for @qsTabRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get qsTabRequests;

  /// No description provided for @qsCatAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get qsCatAll;

  /// No description provided for @qsCatMoving.
  ///
  /// In es, this message translates to:
  /// **'Mudanza'**
  String get qsCatMoving;

  /// No description provided for @qsCatCleaning.
  ///
  /// In es, this message translates to:
  /// **'Limpieza'**
  String get qsCatCleaning;

  /// No description provided for @qsCatAssembly.
  ///
  /// In es, this message translates to:
  /// **'Armado'**
  String get qsCatAssembly;

  /// No description provided for @qsCatEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get qsCatEvents;

  /// No description provided for @qsCatGardening.
  ///
  /// In es, this message translates to:
  /// **'Jardinería'**
  String get qsCatGardening;

  /// No description provided for @qsCatRepairs.
  ///
  /// In es, this message translates to:
  /// **'Reparaciones'**
  String get qsCatRepairs;

  /// No description provided for @qsCatPainting.
  ///
  /// In es, this message translates to:
  /// **'Pintura'**
  String get qsCatPainting;

  /// No description provided for @qsCatPlumbing.
  ///
  /// In es, this message translates to:
  /// **'Plomería'**
  String get qsCatPlumbing;

  /// No description provided for @qsCatElectrical.
  ///
  /// In es, this message translates to:
  /// **'Electricidad'**
  String get qsCatElectrical;

  /// No description provided for @qsCatTech.
  ///
  /// In es, this message translates to:
  /// **'Tecnología'**
  String get qsCatTech;

  /// No description provided for @qsCatPets.
  ///
  /// In es, this message translates to:
  /// **'Mascotas'**
  String get qsCatPets;

  /// No description provided for @qsCatBeauty.
  ///
  /// In es, this message translates to:
  /// **'Belleza'**
  String get qsCatBeauty;

  /// No description provided for @qsCatClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get qsCatClasses;

  /// No description provided for @qsCatCooking.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get qsCatCooking;

  /// No description provided for @qsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar servicios'**
  String get qsLoadError;

  /// No description provided for @qsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay servicios disponibles'**
  String get qsEmptyTitle;

  /// No description provided for @qsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Publica el tuyo con el botón +'**
  String get qsEmptySubtitle;

  /// No description provided for @qsRequestsSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes próximamente'**
  String get qsRequestsSoonTitle;

  /// No description provided for @qsRequestsSoonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pronto podrás publicar lo que necesitas'**
  String get qsRequestsSoonSubtitle;

  /// No description provided for @qsServiceDefault.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get qsServiceDefault;

  /// No description provided for @qsProviderDefault.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get qsProviderDefault;

  /// No description provided for @qsReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} reseñas'**
  String qsReviewsCount(int count);

  /// No description provided for @qsProviderReviewsLine.
  ///
  /// In es, this message translates to:
  /// **'{name} · {count} reseñas'**
  String qsProviderReviewsLine(String name, int count);

  /// No description provided for @qsDotReviewsCount.
  ///
  /// In es, this message translates to:
  /// **' · {count} reseñas'**
  String qsDotReviewsCount(int count);

  /// No description provided for @qsHowItWorks.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona'**
  String get qsHowItWorks;

  /// No description provided for @qsStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Contratas el servicio'**
  String get qsStep1Title;

  /// No description provided for @qsStep1Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Acuerdan fecha, hora y detalles por chat'**
  String get qsStep1Subtitle;

  /// No description provided for @qsStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Se realiza el trabajo'**
  String get qsStep2Title;

  /// No description provided for @qsStep2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'El proveedor marca avances en tiempo real'**
  String get qsStep2Subtitle;

  /// No description provided for @qsStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Confirmas y pagas'**
  String get qsStep3Title;

  /// No description provided for @qsStep3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo pagas cuando estás satisfecho'**
  String get qsStep3Subtitle;

  /// No description provided for @qsHireFor.
  ///
  /// In es, this message translates to:
  /// **'Contratar por {price}/{unit}'**
  String qsHireFor(String price, String unit);

  /// No description provided for @qsSecurePayment.
  ///
  /// In es, this message translates to:
  /// **'Pago seguro · Garantía Atrio'**
  String get qsSecurePayment;

  /// No description provided for @qsConfirmHire.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contratación'**
  String get qsConfirmHire;

  /// No description provided for @qsHireMessage.
  ///
  /// In es, this message translates to:
  /// **'{host} realizará \"{title}\" por {price}/{unit}'**
  String qsHireMessage(String host, String title, String price, String unit);

  /// No description provided for @qsServicePrice.
  ///
  /// In es, this message translates to:
  /// **'Precio del servicio'**
  String get qsServicePrice;

  /// No description provided for @qsAtrioFee.
  ///
  /// In es, this message translates to:
  /// **'Tarifa Atrio (7%)'**
  String get qsAtrioFee;

  /// No description provided for @qsTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get qsTotal;

  /// No description provided for @qsMilestonesTitle.
  ///
  /// In es, this message translates to:
  /// **'Avances del servicio'**
  String get qsMilestonesTitle;

  /// No description provided for @qsMilestoneDetails.
  ///
  /// In es, this message translates to:
  /// **'Acordar detalles'**
  String get qsMilestoneDetails;

  /// No description provided for @qsMilestoneStart.
  ///
  /// In es, this message translates to:
  /// **'En camino / Inicio'**
  String get qsMilestoneStart;

  /// No description provided for @qsMilestoneProgress.
  ///
  /// In es, this message translates to:
  /// **'Trabajo en progreso'**
  String get qsMilestoneProgress;

  /// No description provided for @qsMilestoneDone.
  ///
  /// In es, this message translates to:
  /// **'Finalizado y pagado'**
  String get qsMilestoneDone;

  /// No description provided for @qsConfirmAmount.
  ///
  /// In es, this message translates to:
  /// **'Confirmar {amount}'**
  String qsConfirmAmount(String amount);

  /// No description provided for @qsGoBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get qsGoBack;

  /// No description provided for @qsQuickServicePrefix.
  ///
  /// In es, this message translates to:
  /// **'Servicio Rápido: {title}'**
  String qsQuickServicePrefix(String title);

  /// No description provided for @qsChatHi.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Acabo de solicitar \"{title}\" por {price}. Coordinemos los detalles.'**
  String qsChatHi(String title, String price);

  /// No description provided for @qsRequested.
  ///
  /// In es, this message translates to:
  /// **'¡Servicio solicitado!'**
  String get qsRequested;

  /// No description provided for @psMaxPhotos.
  ///
  /// In es, this message translates to:
  /// **'Máximo {n} fotos'**
  String psMaxPhotos(int n);

  /// No description provided for @psAddPhoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get psAddPhoto;

  /// No description provided for @psGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get psGallery;

  /// No description provided for @psCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get psCamera;

  /// No description provided for @psImageTooLarge.
  ///
  /// In es, this message translates to:
  /// **'Una imagen es demasiado grande (máx 5 MB)'**
  String get psImageTooLarge;

  /// No description provided for @psNotAuthenticated.
  ///
  /// In es, this message translates to:
  /// **'No autenticado'**
  String get psNotAuthenticated;

  /// No description provided for @psServicePublished.
  ///
  /// In es, this message translates to:
  /// **'Servicio publicado exitosamente'**
  String get psServicePublished;

  /// No description provided for @psRequestPublished.
  ///
  /// In es, this message translates to:
  /// **'Solicitud publicada exitosamente'**
  String get psRequestPublished;

  /// No description provided for @psTitleOffer.
  ///
  /// In es, this message translates to:
  /// **'Ofrecer Servicio'**
  String get psTitleOffer;

  /// No description provided for @psTitleRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Servicio'**
  String get psTitleRequest;

  /// No description provided for @psModeOffer.
  ///
  /// In es, this message translates to:
  /// **'Ofrecer'**
  String get psModeOffer;

  /// No description provided for @psModeRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitar'**
  String get psModeRequest;

  /// No description provided for @psLabelServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Título del servicio'**
  String get psLabelServiceTitle;

  /// No description provided for @psLabelWhatYouNeed.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas?'**
  String get psLabelWhatYouNeed;

  /// No description provided for @psHintOfferTitle.
  ///
  /// In es, this message translates to:
  /// **'Ej: Plomero express, Mudanza con camioneta, Armado de muebles IKEA...'**
  String get psHintOfferTitle;

  /// No description provided for @psHintRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Ej: Necesito mover un sofá 3 cuerpos hoy a las 18:00...'**
  String get psHintRequestTitle;

  /// No description provided for @psRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo requerido'**
  String get psRequired;

  /// No description provided for @psLabelDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get psLabelDescription;

  /// No description provided for @psHintOfferDescription.
  ///
  /// In es, this message translates to:
  /// **'Cuenta tu experiencia, herramientas que tienes, zonas donde trabajas y por qué confiar en ti.\nEj: 5 años como electricista certificado, atiendo Santiago Centro, traigo herramientas propias.'**
  String get psHintOfferDescription;

  /// No description provided for @psHintRequestDescription.
  ///
  /// In es, this message translates to:
  /// **'Describe lugar, hora, materiales, accesos y cualquier dato relevante.\nEj: Departamento piso 4 con ascensor, sofá 1.80m, necesito 2 personas.'**
  String get psHintRequestDescription;

  /// No description provided for @psPhotosLabel.
  ///
  /// In es, this message translates to:
  /// **'Fotos (máx {n})'**
  String psPhotosLabel(int n);

  /// No description provided for @psPhotosHint.
  ///
  /// In es, this message translates to:
  /// **'Sube hasta {n} fotos de trabajos previos para generar más confianza.'**
  String psPhotosHint(int n);

  /// No description provided for @psAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get psAdd;

  /// No description provided for @psCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get psCategory;

  /// No description provided for @psCatMoving.
  ///
  /// In es, this message translates to:
  /// **'Mudanza'**
  String get psCatMoving;

  /// No description provided for @psCatCleaning.
  ///
  /// In es, this message translates to:
  /// **'Limpieza'**
  String get psCatCleaning;

  /// No description provided for @psCatAssembly.
  ///
  /// In es, this message translates to:
  /// **'Armado'**
  String get psCatAssembly;

  /// No description provided for @psCatEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get psCatEvents;

  /// No description provided for @psCatGardening.
  ///
  /// In es, this message translates to:
  /// **'Jardinería'**
  String get psCatGardening;

  /// No description provided for @psCatRepairs.
  ///
  /// In es, this message translates to:
  /// **'Reparaciones'**
  String get psCatRepairs;

  /// No description provided for @psCatPainting.
  ///
  /// In es, this message translates to:
  /// **'Pintura'**
  String get psCatPainting;

  /// No description provided for @psCatPlumbing.
  ///
  /// In es, this message translates to:
  /// **'Plomería'**
  String get psCatPlumbing;

  /// No description provided for @psCatElectrical.
  ///
  /// In es, this message translates to:
  /// **'Electricidad'**
  String get psCatElectrical;

  /// No description provided for @psCatTech.
  ///
  /// In es, this message translates to:
  /// **'Tecnología'**
  String get psCatTech;

  /// No description provided for @psCatPets.
  ///
  /// In es, this message translates to:
  /// **'Mascotas'**
  String get psCatPets;

  /// No description provided for @psCatBeauty.
  ///
  /// In es, this message translates to:
  /// **'Belleza'**
  String get psCatBeauty;

  /// No description provided for @psCatClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get psCatClasses;

  /// No description provided for @psCatCooking.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get psCatCooking;

  /// No description provided for @psCatOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get psCatOther;

  /// No description provided for @psPricePerHour.
  ///
  /// In es, this message translates to:
  /// **'Precio por hora (\$)'**
  String get psPricePerHour;

  /// No description provided for @psBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto (\$)'**
  String get psBudget;

  /// No description provided for @psHintPrice25.
  ///
  /// In es, this message translates to:
  /// **'Ej: 25'**
  String get psHintPrice25;

  /// No description provided for @psHintBudget50.
  ///
  /// In es, this message translates to:
  /// **'Ej: 50'**
  String get psHintBudget50;

  /// No description provided for @psNotANumber.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número'**
  String get psNotANumber;

  /// No description provided for @psUrgency.
  ///
  /// In es, this message translates to:
  /// **'Urgencia'**
  String get psUrgency;

  /// No description provided for @psUrgencyToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get psUrgencyToday;

  /// No description provided for @psUrgencyTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get psUrgencyTomorrow;

  /// No description provided for @psUrgencyWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get psUrgencyWeek;

  /// No description provided for @psUrgencyFlexible.
  ///
  /// In es, this message translates to:
  /// **'Flexible'**
  String get psUrgencyFlexible;

  /// No description provided for @psTip.
  ///
  /// In es, this message translates to:
  /// **'Consejo'**
  String get psTip;

  /// No description provided for @psTipOffer.
  ///
  /// In es, this message translates to:
  /// **'Incluye fotos de trabajos anteriores y sé específico sobre tus habilidades para recibir más solicitudes.'**
  String get psTipOffer;

  /// No description provided for @psTipRequest.
  ///
  /// In es, this message translates to:
  /// **'Sé detallado sobre lo que necesitas. Incluye medidas, piso, y si tienes herramientas disponibles.'**
  String get psTipRequest;

  /// No description provided for @psPublishService.
  ///
  /// In es, this message translates to:
  /// **'Publicar Servicio'**
  String get psPublishService;

  /// No description provided for @psPublishRequest.
  ///
  /// In es, this message translates to:
  /// **'Publicar Solicitud'**
  String get psPublishRequest;

  /// No description provided for @clEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Anuncio'**
  String get clEditTitle;

  /// No description provided for @clNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Anuncio'**
  String get clNewTitle;

  /// No description provided for @clMaxImages.
  ///
  /// In es, this message translates to:
  /// **'Máximo 8 imágenes'**
  String get clMaxImages;

  /// No description provided for @clAddImages.
  ///
  /// In es, this message translates to:
  /// **'Agregar imágenes'**
  String get clAddImages;

  /// No description provided for @clGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get clGallery;

  /// No description provided for @clGallerySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar varias fotos'**
  String get clGallerySubtitle;

  /// No description provided for @clCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get clCamera;

  /// No description provided for @clCameraSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto ahora'**
  String get clCameraSubtitle;

  /// No description provided for @clImageTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen es demasiado grande (máx 10 MB)'**
  String get clImageTooLarge;

  /// No description provided for @clCompleteRequired.
  ///
  /// In es, this message translates to:
  /// **'Completa todos los campos requeridos'**
  String get clCompleteRequired;

  /// No description provided for @clValidPrice.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un precio válido mayor a 0'**
  String get clValidPrice;

  /// No description provided for @clValidCapacity.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una capacidad válida'**
  String get clValidCapacity;

  /// No description provided for @clTitleTooLong.
  ///
  /// In es, this message translates to:
  /// **'El título es demasiado largo (máx 200 caracteres)'**
  String get clTitleTooLong;

  /// No description provided for @clPublishedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Anuncio publicado exitosamente'**
  String get clPublishedSuccess;

  /// No description provided for @clStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String clStepOf(int current, int total);

  /// No description provided for @clBack.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get clBack;

  /// No description provided for @clNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get clNext;

  /// No description provided for @clPublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get clPublish;

  /// No description provided for @clCommissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Comisión del 7% (máx \$90.000)'**
  String get clCommissionTitle;

  /// No description provided for @clCommissionDesc.
  ///
  /// In es, this message translates to:
  /// **'Si el 7% supera \$90.000, solo se cobran \$90.000. Transparencia total.'**
  String get clCommissionDesc;

  /// No description provided for @clCategoryQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué vas a ofrecer?'**
  String get clCategoryQuestion;

  /// No description provided for @clCategorySelect.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la categoría que mejor describe tu oferta'**
  String get clCategorySelect;

  /// No description provided for @clTypeSpace.
  ///
  /// In es, this message translates to:
  /// **'Espacio'**
  String get clTypeSpace;

  /// No description provided for @clTypeSpaceDesc.
  ///
  /// In es, this message translates to:
  /// **'Loft, estudio, villa, sala...'**
  String get clTypeSpaceDesc;

  /// No description provided for @clTypeExperience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia'**
  String get clTypeExperience;

  /// No description provided for @clTypeExperienceDesc.
  ///
  /// In es, this message translates to:
  /// **'Tour, clase, taller, evento...'**
  String get clTypeExperienceDesc;

  /// No description provided for @clTypeService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get clTypeService;

  /// No description provided for @clTypeServiceDesc.
  ///
  /// In es, this message translates to:
  /// **'Fotografía, catering, limpieza...'**
  String get clTypeServiceDesc;

  /// No description provided for @clDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles del anuncio'**
  String get clDetailsTitle;

  /// No description provided for @clTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get clTitleLabel;

  /// No description provided for @clTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Loft Industrial con Vista a la Ciudad'**
  String get clTitleHint;

  /// No description provided for @clDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get clDescriptionLabel;

  /// No description provided for @clDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe tu espacio, experiencia o servicio...'**
  String get clDescriptionHint;

  /// No description provided for @clPhotosTitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega fotos'**
  String get clPhotosTitle;

  /// No description provided for @clPhotosSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Las buenas fotos atraen más reservas (max 8)'**
  String get clPhotosSubtitle;

  /// No description provided for @clPhotosAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get clPhotosAdd;

  /// No description provided for @clPhotosCover.
  ///
  /// In es, this message translates to:
  /// **'Portada'**
  String get clPhotosCover;

  /// No description provided for @clPhotosCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 foto seleccionada} other{{count} fotos seleccionadas}}'**
  String clPhotosCount(int count);

  /// No description provided for @clPhotosTapToAdd.
  ///
  /// In es, this message translates to:
  /// **'Toca para agregar fotos'**
  String get clPhotosTapToAdd;

  /// No description provided for @clLocationTitle.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get clLocationTitle;

  /// No description provided for @clAddressLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get clAddressLabel;

  /// No description provided for @clAddressHint.
  ///
  /// In es, this message translates to:
  /// **'Calle, número, colonia'**
  String get clAddressHint;

  /// No description provided for @clCityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get clCityLabel;

  /// No description provided for @clCityHint.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get clCityHint;

  /// No description provided for @clCountryLabel.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get clCountryLabel;

  /// No description provided for @clCountryHint.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get clCountryHint;

  /// No description provided for @clChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get clChange;

  /// No description provided for @clMapSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar en el mapa'**
  String get clMapSelect;

  /// No description provided for @clMapTapToOpen.
  ///
  /// In es, this message translates to:
  /// **'Toca para abrir el mapa'**
  String get clMapTapToOpen;

  /// No description provided for @clLocationSelected.
  ///
  /// In es, this message translates to:
  /// **'Ubicación seleccionada'**
  String get clLocationSelected;

  /// No description provided for @clPricingTitle.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get clPricingTitle;

  /// No description provided for @clPricingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Establece un precio competitivo'**
  String get clPricingSubtitle;

  /// No description provided for @clPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio base (CLP)'**
  String get clPriceLabel;

  /// No description provided for @clChargeBy.
  ///
  /// In es, this message translates to:
  /// **'Cobrar por:'**
  String get clChargeBy;

  /// No description provided for @clUnitNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get clUnitNight;

  /// No description provided for @clUnitHour.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get clUnitHour;

  /// No description provided for @clUnitSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get clUnitSession;

  /// No description provided for @clUnitPerson.
  ///
  /// In es, this message translates to:
  /// **'Persona'**
  String get clUnitPerson;

  /// No description provided for @clCommissionInfo.
  ///
  /// In es, this message translates to:
  /// **'Atrio cobra 7% de comisión por reserva. Si el 7% supera \$90.000 CLP, solo se cobran \$90.000.'**
  String get clCommissionInfo;

  /// No description provided for @rmModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modalidad de reserva'**
  String get rmModeTitle;

  /// No description provided for @rmModeQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo quieres que reserven {typeLabel}?'**
  String rmModeQuestion(String typeLabel);

  /// No description provided for @rmTypeService.
  ///
  /// In es, this message translates to:
  /// **'tu servicio'**
  String get rmTypeService;

  /// No description provided for @rmTypeExperience.
  ///
  /// In es, this message translates to:
  /// **'tu experiencia'**
  String get rmTypeExperience;

  /// No description provided for @rmTypeSpace.
  ///
  /// In es, this message translates to:
  /// **'tu espacio'**
  String get rmTypeSpace;

  /// No description provided for @rmModeNights.
  ///
  /// In es, this message translates to:
  /// **'Por noches'**
  String get rmModeNights;

  /// No description provided for @rmModeNightsDesc.
  ///
  /// In es, this message translates to:
  /// **'Check-in / Check-out por noches'**
  String get rmModeNightsDesc;

  /// No description provided for @rmModeFullDay.
  ///
  /// In es, this message translates to:
  /// **'Día completo'**
  String get rmModeFullDay;

  /// No description provided for @rmModeFullDayDescService.
  ///
  /// In es, this message translates to:
  /// **'Precio por sesión / día'**
  String get rmModeFullDayDescService;

  /// No description provided for @rmModeFullDayDescExperience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia de día completo'**
  String get rmModeFullDayDescExperience;

  /// No description provided for @rmModeFullDayDescSpace.
  ///
  /// In es, this message translates to:
  /// **'Reserva de un día completo'**
  String get rmModeFullDayDescSpace;

  /// No description provided for @rmModeHours.
  ///
  /// In es, this message translates to:
  /// **'Por horas'**
  String get rmModeHours;

  /// No description provided for @rmModeHoursDescService.
  ///
  /// In es, this message translates to:
  /// **'Precio por hora'**
  String get rmModeHoursDescService;

  /// No description provided for @rmModeHoursDescExperience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia con horario específico'**
  String get rmModeHoursDescExperience;

  /// No description provided for @rmModeHoursDescSpace.
  ///
  /// In es, this message translates to:
  /// **'Bloques horarios personalizados'**
  String get rmModeHoursDescSpace;

  /// No description provided for @rmAvailableSchedule.
  ///
  /// In es, this message translates to:
  /// **'Horario disponible'**
  String get rmAvailableSchedule;

  /// No description provided for @rmFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde: {time}'**
  String rmFrom(String time);

  /// No description provided for @rmUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta: {time}'**
  String rmUntil(String time);

  /// No description provided for @rmBlockDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración del bloque'**
  String get rmBlockDuration;

  /// No description provided for @rmBlockDurationHelp.
  ///
  /// In es, this message translates to:
  /// **'El precio base se cobra por cada bloque de horas'**
  String get rmBlockDurationHelp;

  /// No description provided for @rmCapacity.
  ///
  /// In es, this message translates to:
  /// **'Capacidad máxima'**
  String get rmCapacity;

  /// No description provided for @rmCapacityHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 10'**
  String get rmCapacityHint;

  /// No description provided for @rmInstantBooking.
  ///
  /// In es, this message translates to:
  /// **'Reserva instantánea'**
  String get rmInstantBooking;

  /// No description provided for @rmInstantBookingDesc.
  ///
  /// In es, this message translates to:
  /// **'Se confirma automáticamente'**
  String get rmInstantBookingDesc;

  /// No description provided for @rmCancellationPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de cancelación'**
  String get rmCancellationPolicy;

  /// No description provided for @rmFlexible.
  ///
  /// In es, this message translates to:
  /// **'Flexible'**
  String get rmFlexible;

  /// No description provided for @rmModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderada'**
  String get rmModerate;

  /// No description provided for @rmStrict.
  ///
  /// In es, this message translates to:
  /// **'Estricta'**
  String get rmStrict;

  /// No description provided for @rmHours.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 hora} other{{n} horas}}'**
  String rmHours(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
