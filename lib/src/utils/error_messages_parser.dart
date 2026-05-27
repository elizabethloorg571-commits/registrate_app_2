/// 🔍 **Parser de mensajes de error del servidor**
///
/// Esta clase se encarga de transformar mensajes de error técnicos
/// del servidor en mensajes amigables para el usuario final.
///
/// 📋 **Funcionalidades:**
/// - Parseo de excepciones comunes de Flutter/Dart
/// - Detección de errores HTTP por código de estado
/// - Análisis inteligente por palabras clave
/// - Mensajes sanitizados en español
/// - Fallback para errores no reconocidos
///
/// 🎯 **Casos cubiertos:**
/// - Errores de conexión y red
/// - Errores de autenticación y autorización
/// - Errores de validación de datos
/// - Errores de servidor (5xx)
/// - Errores de cliente (4xx)
/// - Timeouts y límites
/// - Errores de formato y parsing
library;

class ErrorMessagesParser {
  /// Mapa de códigos de estado HTTP a mensajes amigables
  static const Map<int, String> _httpStatusMessages = {
    // 4xx - Errores del cliente
    400: 'Solicitud incorrecta. Verifica los datos enviados',
    401: 'No autorizado. Inicia sesión nuevamente',
    402: 'Pago requerido para continuar',
    403: 'Acceso denegado. No tienes permisos suficientes',
    404: 'Recurso no encontrado',
    405: 'Método no permitido',
    406: 'Formato de respuesta no aceptable',
    407: 'Autenticación de proxy requerida',
    408: 'Tiempo de espera agotado',
    409: 'Conflicto con el estado actual del recurso',
    410: 'El recurso ya no está disponible',
    411: 'Longitud requerida',
    412: 'Falló una condición previa',
    413: 'Contenido demasiado grande',
    414: 'URI demasiado larga',
    415: 'Tipo de medio no soportado',
    416: 'Rango no satisfactorio',
    417: 'Falló la expectativa',
    418: 'Soy una tetera ☕', // Easter egg del RFC 2324
    421: 'Solicitud mal dirigida',
    422: 'Entidad no procesable. Verifica tus datos',
    423: 'Recurso bloqueado',
    424: 'Falló la dependencia',
    425: 'Demasiado temprano',
    426: 'Actualización requerida',
    428: 'Condición previa requerida',
    429: 'Demasiadas solicitudes. Intenta más tarde',
    431: 'Campos de encabezado demasiado grandes',
    451: 'No disponible por razones legales',

    // 5xx - Errores del servidor
    500: 'Error interno del servidor',
    501: 'Funcionalidad no implementada',
    502: 'Servidor no disponible temporalmente',
    503: 'Servicio no disponible. Intenta más tarde',
    504: 'Tiempo de espera del servidor agotado',
    505: 'Versión HTTP no soportada',
    506: 'Variante también negocia',
    507: 'Almacenamiento insuficiente',
    508: 'Bucle detectado',
    510: 'No extendido',
    511: 'Autenticación de red requerida',
  };

  /// Mapa de palabras clave a mensajes sanitizados
  static const Map<String, String> _keywordMessages = {
    // Autenticación y autorización
    'unauthorized': 'No autorizado. Inicia sesión nuevamente',
    'forbidden': 'Acceso denegado. No tienes permisos',
    'authentication': 'Error de autenticación. Verifica tus credenciales',
    'login': 'Error al iniciar sesión. Verifica usuario y contraseña',
    'password': 'Contraseña incorrecta',
    'token': 'Sesión expirada. Inicia sesión nuevamente',
    'expired': 'Tu sesión ha expirado',
    'invalid_credentials': 'Credenciales inválidas',
    'access_denied': 'Acceso denegado',

    // Validación de datos
    'validation': 'Verifica los campos ingresados',
    'required': 'Faltan campos obligatorios',
    'invalid': 'Datos inválidos. Revisa la información',
    'format': 'Formato de datos incorrecto',
    'email': 'Formato de email inválido',
    'phone': 'Formato de teléfono inválido',
    'length': 'Longitud de campo incorrecta',
    'minimum': 'Valor menor al mínimo permitido',
    'maximum': 'Valor mayor al máximo permitido',
    'duplicate': 'Ya existe un registro con estos datos',
    'unique': 'Este valor ya está en uso',

    // Red y conexión
    'network': 'Error de conexión. Verifica tu internet',
    'connection': 'Sin conexión. Revisa tu red',
    'timeout': 'Tiempo de espera agotado. Intenta nuevamente',
    'unreachable': 'Servidor no disponible',
    'dns': 'Error de DNS. Verifica tu conexión',
    'socket': 'Error de conexión de red',
    'host': 'No se puede conectar al servidor',

    // Datos y base de datos
    'not_found': 'Elemento no encontrado',
    'exists': 'El elemento ya existe',
    'conflict': 'Conflicto con datos existentes',
    'constraint': 'Error de restricción de datos',
    'foreign_key': 'Error de relación entre datos',
    'database': 'Error en la base de datos',
    'query': 'Error en la consulta de datos',

    // Permisos y límites
    'permission': 'Sin permisos para esta acción',
    'quota': 'Límite de cuota excedido',
    'rate_limit': 'Demasiadas solicitudes. Espera un momento',
    'capacity': 'Capacidad máxima alcanzada',
    'storage': 'Error de almacenamiento',
    'memory': 'Memoria insuficiente',

    // Archivos y contenido
    'file': 'Error con el archivo',
    'upload': 'Error al subir archivo',
    'download': 'Error al descargar archivo',
    'size': 'Tamaño de archivo inválido',
    'type': 'Tipo de archivo no permitido',
    'corrupt': 'Archivo corrupto',
    'missing': 'Archivo no encontrado',

    // Pagos y transacciones
    'payment': 'Error en el pago',
    'transaction': 'Error en la transacción',
    'insufficient': 'Fondos insuficientes',
    'declined': 'Pago rechazado',
    'card': 'Error con la tarjeta',
    'expired_card': 'Tarjeta expirada',

    // Servidor y servicios
    'maintenance': 'Servicio en mantenimiento',
    'unavailable': 'Servicio no disponible',
    'overload': 'Servidor sobrecargado',
    'internal': 'Error interno del servidor',
    'gateway': 'Error de puerta de enlace',
    'proxy': 'Error de proxy',

    // Configuración y sistema
    'configuration': 'Error de configuración',
    'version': 'Versión no compatible',
    'update': 'Actualización requerida',
    'compatibility': 'Problema de compatibilidad',
    'deprecated': 'Funcionalidad obsoleta',
  };

  /// Patrones regex para casos específicos
  static final Map<RegExp, String> _regexPatterns = {
    // Códigos de error HTTP en el mensaje
    RegExp(r'http\s*(?:error\s*)?(\d{3})', caseSensitive: false):
        'Error HTTP {code}',

    // Errores de JSON/parsing
    RegExp(r'json|parse|format', caseSensitive: false):
        'Error en el formato de respuesta',

    // Errores de email específicos
    RegExp(
      r'invalid\s+email|email\s+invalid|malformed\s+email',
      caseSensitive: false,
    ): 'Formato de email inválido',

    // Errores de conexión específicos
    RegExp(
      r'failed\s+to\s+connect|connection\s+refused|no\s+route\s+to\s+host',
      caseSensitive: false,
    ): 'No se puede conectar al servidor',

    // Errores de timeout específicos
    RegExp(r'timeout|timed\s+out|time\s+limit', caseSensitive: false):
        'Tiempo de espera agotado',

    // Errores de certificado SSL
    RegExp(r'certificate|ssl|tls', caseSensitive: false):
        'Error de certificado de seguridad',

    // Errores de memoria
    RegExp(r'out\s+of\s+memory|memory\s+error', caseSensitive: false):
        'Memoria insuficiente',
  };

  /// **Método principal para sanitizar errores**
  ///
  /// Toma cualquier error y devuelve un mensaje amigable para el usuario
  static String sanitizeError(Object e) {
    final String originalMessage = e.toString().toLowerCase();
    String cleanMessage = originalMessage;

    // 1. Remover prefijos de excepciones comunes
    cleanMessage = _removeExceptionPrefixes(cleanMessage);

    // 2. Detectar códigos de estado HTTP
    final String? httpMessage = _parseHttpStatus(cleanMessage);
    if (httpMessage != null) return httpMessage;

    // 3. Aplicar patrones regex específicos
    final String? regexMessage = _applyRegexPatterns(cleanMessage);
    if (regexMessage != null) return regexMessage;

    // 4. Buscar palabras clave
    final String? keywordMessage = _parseByKeywords(cleanMessage);
    if (keywordMessage != null) return keywordMessage;

    // 5. Casos especiales comunes
    final String? specialMessage = _parseSpecialCases(cleanMessage);
    if (specialMessage != null) return specialMessage;

    // 6. Fallback para errores no reconocidos
    return _getFallbackMessage(originalMessage);
  }

  /// Remueve prefijos comunes de excepciones de Flutter/Dart
  static String _removeExceptionPrefixes(String message) {
    final prefixes = [
      'exception: ',
      'socketexception: ',
      'httpexception: ',
      'formatexception: ',
      'timeoutexception: ',
      'platformexception: ',
      'argumentexception: ',
      'stateexception: ',
      'error: ',
      'failure: ',
    ];

    String cleaned = message;
    for (String prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.replaceFirst(prefix, '').trim();
      }
    }
    return cleaned;
  }

  /// Detecta y parsea códigos de estado HTTP
  static String? _parseHttpStatus(String message) {
    // Buscar códigos HTTP en el mensaje
    final RegExp httpCodeRegex = RegExp(r'(\d{3})');
    final Match? match = httpCodeRegex.firstMatch(message);

    if (match != null) {
      final int? statusCode = int.tryParse(match.group(1)!);
      if (statusCode != null && _httpStatusMessages.containsKey(statusCode)) {
        return _httpStatusMessages[statusCode];
      }
    }
    return null;
  }

  /// Aplica patrones regex específicos
  static String? _applyRegexPatterns(String message) {
    for (MapEntry<RegExp, String> entry in _regexPatterns.entries) {
      if (entry.key.hasMatch(message)) {
        // Si el patrón incluye {code}, intentar extraer el código
        if (entry.value.contains('{code}')) {
          final RegExp codeRegex = RegExp(r'(\d{3})');
          final Match? match = codeRegex.firstMatch(message);
          if (match != null) {
            return entry.value.replaceAll('{code}', match.group(1)!);
          }
        }
        return entry.value;
      }
    }
    return null;
  }

  /// Busca palabras clave en el mensaje
  static String? _parseByKeywords(String message) {
    // Ordenar por longitud descendente para priorizar palabras más específicas
    final List<String> sortedKeywords = _keywordMessages.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String keyword in sortedKeywords) {
      if (message.contains(keyword)) {
        return _keywordMessages[keyword];
      }
    }
    return null;
  }

  /// Maneja casos especiales comunes
  static String? _parseSpecialCases(String message) {
    // Casos específicos de la aplicación o patrones únicos

    if (message.contains('no internet') ||
        message.contains('network unreachable')) {
      return 'Sin conexión a internet';
    }

    if (message.contains('server error') ||
        message.contains('internal server')) {
      return 'Error del servidor. Intenta más tarde';
    }

    if (message.contains('bad request')) {
      return 'Solicitud incorrecta. Verifica los datos';
    }

    if (message.contains('service unavailable')) {
      return 'Servicio temporalmente no disponible';
    }

    if (message.contains('too many requests')) {
      return 'Demasiadas solicitudes. Espera un momento';
    }

    if (message.contains('session expired') ||
        message.contains('token expired')) {
      return 'Tu sesión ha expirado. Inicia sesión nuevamente';
    }

    if (message.contains('file too large')) {
      return 'El archivo es demasiado grande';
    }

    if (message.contains('unsupported media type')) {
      return 'Tipo de archivo no soportado';
    }

    return null;
  }

  /// Mensaje de fallback para errores no reconocidos
  static String _getFallbackMessage(String originalMessage) {
    // Si el mensaje original es muy técnico o largo, usar mensaje genérico
    if (originalMessage.length > 100 ||
        originalMessage.contains('stack trace') ||
        originalMessage.contains('at ') ||
        originalMessage.contains('#0') ||
        originalMessage.contains('lib/')) {
      return 'Ocurrió un error inesperado. Intenta nuevamente';
    }

    // Si el mensaje parece legible, capitalizarlo y devolverlo
    String capitalized = originalMessage.trim();
    if (capitalized.isNotEmpty) {
      capitalized = capitalized[0].toUpperCase() + capitalized.substring(1);
      // Añadir punto si no termina en puntuación
      if (!capitalized.endsWith('.') &&
          !capitalized.endsWith('!') &&
          !capitalized.endsWith('?')) {
        capitalized += '.';
      }
      return capitalized;
    }

    return 'Ocurrió un error inesperado';
  }

  /// **Método auxiliar para testing y debug**
  ///
  /// Devuelve información detallada sobre cómo se parseó el error
  static Map<String, dynamic> debugSanitizeError(Object e) {
    final String originalMessage = e.toString();
    final String lowerMessage = originalMessage.toLowerCase();
    final String cleanMessage = _removeExceptionPrefixes(lowerMessage);

    final Map<String, dynamic> debugInfo = {
      'original': originalMessage,
      'cleaned': cleanMessage,
      'sanitized': sanitizeError(e),
      'matchedPattern': null,
      'matchedKeyword': null,
      'httpCode': null,
    };

    // Detectar qué patrón coincidió
    final String? httpMessage = _parseHttpStatus(cleanMessage);
    if (httpMessage != null) {
      debugInfo['matchedPattern'] = 'HTTP Status';
      final RegExp httpCodeRegex = RegExp(r'(\d{3})');
      final Match? match = httpCodeRegex.firstMatch(cleanMessage);
      if (match != null) {
        debugInfo['httpCode'] = int.tryParse(match.group(1)!);
      }
      return debugInfo;
    }

    // Buscar regex patterns
    for (MapEntry<RegExp, String> entry in _regexPatterns.entries) {
      if (entry.key.hasMatch(cleanMessage)) {
        debugInfo['matchedPattern'] = 'Regex: ${entry.key.pattern}';
        return debugInfo;
      }
    }

    // Buscar keywords
    final List<String> sortedKeywords = _keywordMessages.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String keyword in sortedKeywords) {
      if (cleanMessage.contains(keyword)) {
        debugInfo['matchedKeyword'] = keyword;
        debugInfo['matchedPattern'] = 'Keyword';
        return debugInfo;
      }
    }

    // Buscar casos especiales
    if (_parseSpecialCases(cleanMessage) != null) {
      debugInfo['matchedPattern'] = 'Special Case';
    } else {
      debugInfo['matchedPattern'] = 'Fallback';
    }

    return debugInfo;
  }
}
