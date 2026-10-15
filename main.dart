import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

/// Modo de juego: adivinar un número (1-100) o una letra (A-Z).
enum ModoJuego { numero, letra }

/// Formateador que convierte lo que se escribe a mayúsculas al instante.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adivina el Número o la Letra',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4361EE),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B93FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121016),
      ),
      home: MyHomePage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MyHomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  static const String _alfabeto = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const List<String> _vocales = ['A', 'E', 'I', 'O', 'U'];

  ModoJuego _modo = ModoJuego.numero;

  late int _numeroSecreto;
  late String _letraSecreta;

  // Límites del rango posible, se van cerrando con cada intento.
  int _rangoMinNum = 1;
  int _rangoMaxNum = 100;
  int _rangoMinLetra = 65; // código ASCII de 'A'
  int _rangoMaxLetra = 90; // código ASCII de 'Z'

  int _intentos = 0;
  int _intentosRestantes = 5;
  String _mensaje = '';
  final TextEditingController _controller = TextEditingController();
  bool _juegoTerminado = false;
  bool _juegoPerdido = false;
  bool _pistaUsada = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<ModoJuego, int?> _mejorPuntaje = {
    ModoJuego.numero: null,
    ModoJuego.letra: null,
  };

  final List<String> _mensajesInicialesNumero = [
    '🎯 ¡Adivina el número secreto! (1-100)',
    '🔮 Desafío mental activo... ¿Cuál será?',
    '✨ Tienes 5 oportunidades de oro',
    '🌟 Concéntrate y prueba tu suerte',
  ];

  final List<String> _mensajesInicialesLetra = [
    '🔤 ¡Adivina la letra secreta! (A-Z)',
    '🧩 Una letra se esconde en el abecedario...',
    '✨ Tienes 5 oportunidades de oro',
    '🌟 Piensa bien y prueba tu suerte',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _iniciarJuego();
  }

  void _iniciarJuego() {
    setState(() {
      if (_modo == ModoJuego.numero) {
        _numeroSecreto = Random().nextInt(100) + 1;
        _mensaje =
            _mensajesInicialesNumero[Random().nextInt(
              _mensajesInicialesNumero.length,
            )];
        _rangoMinNum = 1;
        _rangoMaxNum = 100;
      } else {
        _letraSecreta = _alfabeto[Random().nextInt(_alfabeto.length)];
        _mensaje =
            _mensajesInicialesLetra[Random().nextInt(
              _mensajesInicialesLetra.length,
            )];
        _rangoMinLetra = 65;
        _rangoMaxLetra = 90;
      }
      _intentos = 0;
      _intentosRestantes = 5;
      _juegoTerminado = false;
      _juegoPerdido = false;
      _pistaUsada = false;
      _controller.clear();
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _cambiarModo(ModoJuego nuevoModo) {
    if (nuevoModo == _modo) return;
    setState(() {
      _modo = nuevoModo;
    });
    _iniciarJuego();
    HapticFeedback.selectionClick();
  }

  /// Devuelve un emoji de "temperatura" según qué tan cerca está el intento,
  /// en proporción al rango total posible (100 para números, 26 para letras).
  String _temperatura(int diferencia, int rangoMaximo) {
    final double proporcion = diferencia / rangoMaximo;
    if (proporcion <= 0.03) return '🔥🔥 ¡Ardiendo!';
    if (proporcion <= 0.10) return '🔥 Muy caliente';
    if (proporcion <= 0.25) return '🌤️ Tibio';
    return '❄️ Frío';
  }

  void _usarPista() {
    if (_pistaUsada || _juegoTerminado || _juegoPerdido) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pistaUsada = true;
      if (_modo == ModoJuego.numero) {
        final bool esPar = _numeroSecreto % 2 == 0;
        _mostrarMensajeTemporal(
          '💡 Pista: el número es ${esPar ? "PAR" : "IMPAR"}',
          Colors.indigo.shade400,
        );
      } else {
        final bool esVocal = _vocales.contains(_letraSecreta);
        _mostrarMensajeTemporal(
          '💡 Pista: la letra es una ${esVocal ? "VOCAL" : "CONSONANTE"}',
          Colors.indigo.shade400,
        );
      }
    });
  }

  void _verificarAdivinanza() {
    if (_juegoTerminado || _juegoPerdido) return;

    final String texto = _controller.text.trim();
    if (texto.isEmpty) {
      _mostrarMensajeTemporal(
        _modo == ModoJuego.numero
            ? '📝 ¡Ingresa un número obligatoriamente!'
            : '📝 ¡Ingresa una letra obligatoriamente!',
        Colors.amber.shade800,
      );
      return;
    }

    if (_modo == ModoJuego.numero) {
      _procesarIntentoNumero(texto);
    } else {
      _procesarIntentoLetra(texto);
    }
  }

  void _procesarIntentoNumero(String texto) {
    final int? adivinanza = int.tryParse(texto);
    if (adivinanza == null || adivinanza < 1 || adivinanza > 100) {
      _mostrarMensajeTemporal(
        '🚫 ¡Solo números enteros del 1 al 100!',
        Colors.red.shade600,
      );
      return;
    }

    final int diferencia = (adivinanza - _numeroSecreto).abs();

    setState(() {
      _intentos++;
      _intentosRestantes--;
      _controller.clear();

      if (adivinanza == _numeroSecreto) {
        _mensaje = _mensajeVictoria();
        _juegoTerminado = true;
        _actualizarMejorPuntaje();
        HapticFeedback.heavyImpact();
      } else if (_intentosRestantes == 0) {
        _mensaje =
            '💀 ¡GAME OVER! 💀\nEl número secreto era el $_numeroSecreto';
        _juegoPerdido = true;
        HapticFeedback.heavyImpact();
      } else {
        if (adivinanza < _numeroSecreto) {
          _rangoMinNum = adivinanza;
        } else {
          _rangoMaxNum = adivinanza;
        }
        final String temp = _temperatura(diferencia, 100);
        final String direccion = adivinanza < _numeroSecreto
            ? '⬆️ Sube'
            : '⬇️ Baja';
        _mensaje = '$direccion más. $temp\nTe quedan $_intentosRestantes';
        HapticFeedback.lightImpact();
      }
    });

    _animationController.reset();
    _animationController.forward();
  }

  void _procesarIntentoLetra(String texto) {
    final String letra = texto.toUpperCase();
    if (letra.length != 1 || !_alfabeto.contains(letra)) {
      _mostrarMensajeTemporal(
        '🚫 ¡Solo una letra de la A a la Z!',
        Colors.red.shade600,
      );
      return;
    }

    final int diferencia = (letra.codeUnitAt(0) - _letraSecreta.codeUnitAt(0))
        .abs();

    setState(() {
      _intentos++;
      _intentosRestantes--;
      _controller.clear();

      if (letra == _letraSecreta) {
        _mensaje = _mensajeVictoria();
        _juegoTerminado = true;
        _actualizarMejorPuntaje();
        HapticFeedback.heavyImpact();
      } else if (_intentosRestantes == 0) {
        _mensaje = '💀 ¡GAME OVER! 💀\nLa letra secreta era la $_letraSecreta';
        _juegoPerdido = true;
        HapticFeedback.heavyImpact();
      } else {
        final int code = letra.codeUnitAt(0);
        if (code < _letraSecreta.codeUnitAt(0)) {
          _rangoMinLetra = code;
        } else {
          _rangoMaxLetra = code;
        }
        final String temp = _temperatura(diferencia, 26);
        final String direccion =
            letra.codeUnitAt(0) < _letraSecreta.codeUnitAt(0)
            ? '⬆️ Ve más adelante en el abecedario'
            : '⬇️ Ve más atrás en el abecedario';
        _mensaje = '$direccion. $temp\nTe quedan $_intentosRestantes';
        HapticFeedback.lightImpact();
      }
    });

    _animationController.reset();
    _animationController.forward();
  }

  String _mensajeVictoria() {
    return '🔥 ¡LEGENDARIO! ¡ACERTASTE! 🔥\n'
        'Lo lograste en $_intentos ${_intentos == 1 ? 'intento' : 'intentos'}';
  }

  void _actualizarMejorPuntaje() {
    final int? actual = _mejorPuntaje[_modo];
    if (actual == null || _intentos < actual) {
      _mejorPuntaje[_modo] = _intentos;
    }
  }

  void _mostrarMensajeTemporal(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getMensajeColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_juegoTerminado) return Colors.green.shade600;
    if (_juegoPerdido) return Colors.red.shade600;
    if (_mensaje.contains('Sube') || _mensaje.contains('adelante')) {
      return Colors.blue.shade700;
    }
    if (_mensaje.contains('Baja') || _mensaje.contains('atrás')) {
      return Colors.orange.shade800;
    }
    return scheme.primary;
  }

  List<Color> _gradientColors(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    if (_modo == ModoJuego.numero) {
      return dark
          ? [
              const Color(0xFF13204A),
              const Color(0xFF1E3A8A),
              const Color(0xFF0B1226),
            ]
          : [
              const Color(0xFF4361EE),
              const Color(0xFF4895EF),
              const Color(0xFFBFD3FF),
            ];
    } else {
      return dark
          ? [
              const Color(0xFF0F3D3E),
              const Color(0xFF1B5E5A),
              const Color(0xFF102025),
            ]
          : [
              Colors.teal.shade400,
              Colors.cyan.shade200,
              Colors.lightBlue.shade100,
            ];
    }
  }

  Color _accentColor(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    if (_modo == ModoJuego.numero) {
      return dark ? const Color(0xFF7B93FF) : const Color(0xFF4361EE);
    }
    return dark ? Colors.tealAccent.shade200 : Colors.teal.shade700;
  }

  Widget _rangoChip(String texto, Color color) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Barra que muestra visualmente el rango donde puede estar el valor secreto,
  /// y que se va cerrando (achicando) con cada intento.
  Widget _buildRangoBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color accent = _accentColor(context);

    final int totalMin = _modo == ModoJuego.numero ? 1 : 65;
    final int totalMax = _modo == ModoJuego.numero ? 100 : 90;
    final int curMin = _modo == ModoJuego.numero
        ? _rangoMinNum
        : _rangoMinLetra;
    final int curMax = _modo == ModoJuego.numero
        ? _rangoMaxNum
        : _rangoMaxLetra;
    final String minLabel = _modo == ModoJuego.numero
        ? '$curMin'
        : String.fromCharCode(curMin);
    final String maxLabel = _modo == ModoJuego.numero
        ? '$curMax'
        : String.fromCharCode(curMax);

    final double startFrac = (curMin - totalMin) / (totalMax - totalMin);
    final double endFrac = (curMax - totalMin) / (totalMax - totalMin);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📏 Rango posible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final double chipHalf = 17;
              final double width = constraints.maxWidth;
              final double rawLeft = startFrac * width;
              final double rawWidth = (endFrac - startFrac) * width;
              final double barWidth = rawWidth < 8 ? 8 : rawWidth;
              final double leftPx = rawLeft.clamp(0.0, width - barWidth);

              return SizedBox(
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Riel de fondo (rango total 1-100 o A-Z)
                    Positioned(
                      top: 13,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Segmento activo: el rango donde aún puede estar el valor
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      top: 13,
                      left: leftPx,
                      width: barWidth,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent.withOpacity(0.75), accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Etiqueta con el límite inferior
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      top: 0,
                      left: (leftPx - chipHalf).clamp(
                        0.0,
                        width - chipHalf * 2,
                      ),
                      child: _rangoChip(minLabel, accent),
                    ),
                    // Etiqueta con el límite superior
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      top: 0,
                      left: (leftPx + barWidth - chipHalf).clamp(
                        0.0,
                        width - chipHalf * 2,
                      ),
                      child: _rangoChip(maxLabel, accent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool peligro =
        _intentosRestantes <= 2 && !_juegoTerminado && !_juegoPerdido;
    final scheme = Theme.of(context).colorScheme;
    final int? mejor = _mejorPuntaje[_modo];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors(context),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón de tema claro/oscuro arriba a la derecha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: widget.isDarkMode
                                  ? 'Cambiar a modo claro'
                                  : 'Cambiar a modo oscuro',
                              icon: Icon(
                                widget.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: _accentColor(context),
                              ),
                              onPressed: widget.onToggleTheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Selector de modo: Número o Letra
                      SegmentedButton<ModoJuego>(
                        segments: const [
                          ButtonSegment(
                            value: ModoJuego.numero,
                            label: Text('Número'),
                            icon: Icon(Icons.pin),
                          ),
                          ButtonSegment(
                            value: ModoJuego.letra,
                            label: Text('Letra'),
                            icon: Icon(Icons.abc),
                          ),
                        ],
                        selected: {_modo},
                        onSelectionChanged: (nuevoSet) =>
                            _cambiarModo(nuevoSet.first),
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.85),
                          selectedBackgroundColor: _accentColor(context),
                          selectedForegroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Encabezado con ícono vibrante
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor(context).withOpacity(0.35),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _juegoTerminado
                              ? Icons.emoji_events
                              : (_juegoPerdido
                                    ? Icons.sentiment_very_dissatisfied
                                    : (_modo == ModoJuego.numero
                                          ? Icons.bolt
                                          : Icons.text_fields)),
                          size: 65,
                          color: _juegoTerminado
                              ? Colors.amber.shade700
                              : (_juegoPerdido
                                    ? Colors.red.shade600
                                    : _accentColor(context)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Restricción visual rápida
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _modo == ModoJuego.numero
                              ? '🔢 Rango permitido: 1 al 100 (solo números)'
                              : '🔤 Rango permitido: A a la Z (solo letras)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barra visual del rango, se va cerrando con cada intento
                      _buildRangoBar(context),
                      const SizedBox(height: 16),

                      // Mejor puntaje del modo actual
                      if (mejor != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Text(
                              '🏆 Mejor puntaje: $mejor ${mejor == 1 ? 'intento' : 'intentos'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ),

                      // Tarjeta de mensaje principal
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _mensaje,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getMensajeColor(context),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Contador de intentos dinámico
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: peligro
                              ? Colors.red.shade100
                              : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: peligro
                                ? Colors.red.shade400
                                : Colors.amber.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              peligro
                                  ? Icons.local_fire_department
                                  : Icons.favorite,
                              color: peligro
                                  ? Colors.red.shade700
                                  : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Vidas / Intentos: $_intentosRestantes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: peligro
                                    ? Colors.red.shade800
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón de pista
                      TextButton.icon(
                        onPressed:
                            (_pistaUsada || _juegoTerminado || _juegoPerdido)
                            ? null
                            : _usarPista,
                        icon: Icon(
                          Icons.lightbulb,
                          color: _pistaUsada
                              ? Colors.grey
                              : Colors.amber.shade300,
                        ),
                        label: Text(
                          _pistaUsada
                              ? 'Pista ya usada'
                              : 'Usar pista (gratis, 1 vez)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _pistaUsada ? Colors.grey : Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Campo de texto estricto (número o letra según el modo)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor(context).withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          keyboardType: _modo == ModoJuego.numero
                              ? TextInputType.number
                              : TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: _modo == ModoJuego.numero
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ]
                              : [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[a-zA-Z]'),
                                  ),
                                  LengthLimitingTextInputFormatter(1),
                                  _UpperCaseTextFormatter(),
                                ],
                          textAlign: TextAlign.center,
                          enabled: !_juegoTerminado && !_juegoPerdido,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: _modo == ModoJuego.numero
                                ? 'Ej. 50'
                                : 'Ej. M',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: scheme.surface,
                            prefixIcon: Icon(
                              _modo == ModoJuego.numero ? Icons.pin : Icons.abc,
                              color: _accentColor(context),
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => _controller.clear(),
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _verificarAdivinanza(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón principal vibrante
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: (_juegoTerminado || _juegoPerdido)
                              ? null
                              : _verificarAdivinanza,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _juegoTerminado
                                ? Colors.green.shade600
                                : (_juegoPerdido
                                      ? Colors.red.shade600
                                      : _accentColor(context)),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 8,
                            shadowColor: _accentColor(context).withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _juegoTerminado
                                    ? Icons.check_circle
                                    : (_juegoPerdido
                                          ? Icons.cancel
                                          : Icons.send_rounded),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _juegoTerminado
                                    ? '¡Ganaste!'
                                    : (_juegoPerdido
                                          ? 'Juego terminado'
                                          : '¡Adivinar!'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Botón de reinicio si acabó
                      if (_juegoTerminado || _juegoPerdido)
                        ScaleTransition(
                          scale: _fadeAnimation,
                          child: OutlinedButton.icon(
                            onPressed: _iniciarJuego,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              backgroundColor: Colors.black.withOpacity(0.25),
                            ),
                            icon: const Icon(Icons.replay, color: Colors.white),
                            label: const Text(
                              'Jugar de nuevo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
