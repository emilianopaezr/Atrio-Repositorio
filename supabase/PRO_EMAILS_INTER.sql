-- =============================================
-- PRO_EMAILS_INTER.sql
-- Rebuild the shared email shell so every email uses the Inter
-- typeface (matches the in-app typography). Keeps all three flows
-- (signup verification, password reset, password-changed
-- confirmation) — only the shell changes, so the RPCs and the
-- trigger don't need to be redeclared.
-- Idempotent.
-- =============================================

DROP FUNCTION IF EXISTS atrio_email_shell(TEXT, TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION atrio_email_shell(
  p_preheader TEXT,
  p_heading   TEXT,
  p_body_html TEXT,
  p_cta_label TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CONCAT(
    '<!doctype html>',
    '<html lang="es">',
    '<head>',
      '<meta charset="utf-8">',
      '<meta name="viewport" content="width=device-width,initial-scale=1">',
      '<meta name="color-scheme" content="light only">',
      '<meta name="supported-color-schemes" content="light only">',
      '<title>Atrio</title>',
      -- Load Inter from Google Fonts. Apple Mail, Gmail web, and most
      -- mobile clients honour this link; Outlook desktop ignores it
      -- and falls back to the system-font stack below — that's why
      -- every font-family declaration starts with Inter and ends with
      -- the Apple / Segoe / Roboto fallback chain.
      '<link rel="preconnect" href="https://fonts.googleapis.com">',
      '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>',
      '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">',
      '<style>',
        -- Reset
        'body{margin:0;padding:0;width:100%!important;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}',
        'table{border-collapse:collapse!important;}',
        'img{border:0;outline:none;text-decoration:none;-ms-interpolation-mode:bicubic;}',
        -- Inter everywhere with system-font fallback chain
        '.atrio-body,.atrio-body *{font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif!important;}',
        -- Mobile tweaks
        '@media only screen and (max-width:480px){',
          '.atrio-card{border-radius:0!important;}',
          '.atrio-pad{padding-left:24px!important;padding-right:24px!important;}',
          '.atrio-code{font-size:30px!important;letter-spacing:10px!important;}',
        '}',
      '</style>',
    '</head>',
    '<body class="atrio-body" style="margin:0;padding:0;background:#f4f4f4;color:#0a0a0a;">',
      -- Hidden preheader
      '<div style="display:none;font-size:1px;color:#f4f4f4;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">',
        p_preheader,
      '</div>',
      '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f4f4f4;padding:40px 16px;">',
        '<tr><td align="center">',
          '<table role="presentation" width="600" class="atrio-card" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:24px;overflow:hidden;box-shadow:0 8px 32px rgba(10,10,10,0.06);">',
            -- Lime stripe at the very top
            '<tr><td style="background:#D4FF00;height:6px;line-height:6px;font-size:6px;">&nbsp;</td></tr>',
            -- Isologo (centrado, sin eyebrow)
            '<tr><td align="center" class="atrio-pad" style="padding:48px 40px 4px;">',
              '<img src="https://raw.githubusercontent.com/emilianopaezr/Atrio-Repositorio/main/assets/images/isotipo_atrio_negro.png" alt="Atrio" width="132" style="display:block;width:132px;max-width:55%;height:auto;border:0;">',
            '</td></tr>',
            -- Heading (Inter Bold, tight tracking — editorial)
            '<tr><td align="center" class="atrio-pad" style="padding:0 40px;">',
              '<h1 style="margin:32px 0 8px;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:30px;font-weight:800;letter-spacing:-0.8px;color:#0a0a0a;line-height:1.15;">',
                p_heading,
              '</h1>',
            '</td></tr>',
            -- Body content
            '<tr><td class="atrio-pad" style="padding:12px 48px 36px;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:15px;font-weight:500;line-height:1.65;color:#3a3a3a;letter-spacing:-0.1px;">',
              p_body_html,
            '</td></tr>',
            -- Subtle divider
            '<tr><td class="atrio-pad" style="padding:0 40px;">',
              '<div style="height:1px;background:#ececec;line-height:1px;font-size:1px;">&nbsp;</div>',
            '</td></tr>',
            -- Footer
            '<tr><td class="atrio-pad" style="padding:28px 40px 36px;background:#fafafa;">',
              '<p style="margin:0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:12px;font-weight:500;line-height:1.6;color:#7a7a7a;text-align:center;letter-spacing:-0.05px;">',
                '¿No solicitaste este email? Puedes ignorarlo con seguridad.<br>',
                'Tu cuenta de Atrio sigue protegida.',
              '</p>',
              '<p style="margin:18px 0 0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:10.5px;font-weight:600;line-height:1.55;color:#9a9a9a;text-align:center;letter-spacing:1.2px;text-transform:uppercase;">',
                'Atrio · Marketplace premium',
              '</p>',
              '<p style="margin:6px 0 0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:11.5px;font-weight:500;line-height:1.5;color:#9a9a9a;text-align:center;">',
                '<a href="mailto:contacto@atriocompany.cloud" style="color:#9a9a9a;text-decoration:none;border-bottom:1px solid #cfcfcf;padding-bottom:1px;">contacto@atriocompany.cloud</a>',
              '</p>',
            '</td></tr>',
          '</table>',
          -- Bottom legal
          '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;">',
            '<tr><td align="center" style="padding:18px 0 0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:11px;font-weight:500;color:#9a9a9a;letter-spacing:-0.05px;">',
              '© Atrio Company · Todos los derechos reservados',
            '</td></tr>',
          '</table>',
        '</td></tr>',
      '</table>',
    '</body>',
    '</html>'
  );
$$;

-- Verification: shell exists and outputs Inter-loaded HTML
SELECT
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'atrio_email_shell') AS shell_exists,
  position('Inter' IN atrio_email_shell('pre', 'h', 'body')) > 0 AS uses_inter;
