import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:provider/provider.dart';
import '../../../data/repositories/participante_repository.dart';

class ImportarParticipantesScreen extends StatefulWidget {
  final int eventoId;

  const ImportarParticipantesScreen({super.key, required this.eventoId});

  @override
  State<ImportarParticipantesScreen> createState() => _ImportarParticipantesScreenState();
}

class _ImportarParticipantesScreenState extends State<ImportarParticipantesScreen> {
  List<_FilaPreview> filas = [];
  bool cargando = false;
  bool importando = false;
  String? error;
  String nombreArchivo = '';

  String _cellValue(dynamic cell) => cell == null ? '' : cell.toString().trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seleccionarArchivo());
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final file = result.files.first;
    nombreArchivo = file.name;
    setState(() => cargando = true);

    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('No se pudo leer el archivo');

      List<List<dynamic>>? rows;

      if (file.name.endsWith('.csv')) {
        String csvText = utf8.decode(bytes);
        csvText = csvText.replaceFirst('\uFEFF', '').trim();

        String delimiter = ',';
        final primeraLinea = csvText.split('\n').first.trim();
        if (primeraLinea.contains(';')) delimiter = ';';

        rows = CsvToListConverter(
          shouldParseNumbers: false,
          fieldDelimiter: delimiter,
        ).convert(csvText);

        rows = rows.where((r) => r.any((c) => c != null && c.toString().trim().isNotEmpty)).toList();
      } else if (file.name.endsWith('.xlsx')) {
        try {
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables.values.firstOrNull;
          if (sheet == null) throw Exception('El archivo Excel está vacío');
          rows = sheet.rows.map((r) => r.map((c) => c?.value ?? '').toList()).toList();
        } on FormatException {
          throw Exception('El archivo Excel no es válido. Asegúrate de guardarlo desde Excel real como .xlsx');
        }
      } else {
        throw Exception('Formato no soportado. Usa archivos .csv o .xlsx');
      }

      if (rows.isEmpty) throw Exception('El archivo está vacío');

      final headers = rows[0].map((h) => _cellValue(h).toLowerCase()).toList();
      final idxNombre = headers.indexWhere((h) => h == 'nombre');
      final idxDni = headers.indexWhere((h) => h == 'dni');
      final idxCorreo = headers.indexWhere((h) => h == 'correo');
      final idxTelefono = headers.indexWhere((h) => h == 'telefono');

      if (idxNombre == -1 || idxDni == -1) {
        throw Exception('El archivo debe tener columnas "nombre" y "dni"');
      }

      final parsed = <_FilaPreview>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final nombre = idxNombre < row.length ? _cellValue(row[idxNombre]) : '';
        final dni = idxDni < row.length ? _cellValue(row[idxDni]) : '';
        final correo = idxCorreo >= 0 && idxCorreo < row.length ? _cellValue(row[idxCorreo]) : '';
        final telefono = idxTelefono >= 0 && idxTelefono < row.length ? _cellValue(row[idxTelefono]) : '';

        String? errorMsg;
        if (nombre.isEmpty) {
          errorMsg = 'nombre vacío';
        } else if (dni.isEmpty) {
          errorMsg = 'DNI vacío';
        }

        parsed.add(_FilaPreview(
          numero: i,
          nombre: nombre,
          dni: dni,
          correo: correo,
          telefono: telefono,
          error: errorMsg,
        ));
      }

      if (parsed.isEmpty) throw Exception('No hay datos válidos en el archivo');

      setState(() {
        filas = parsed;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  Future<void> _importar() async {
    final validas = filas.where((f) => f.error == null).toList();
    if (validas.isEmpty) return;

    setState(() => importando = true);

    try {
      final repo = context.read<ParticipanteRepository>();
      final payload = validas.map((f) => {
        'nombre': f.nombre,
        'dni': f.dni,
        'correo': f.correo,
        'telefono': f.telefono,
      }).toList();

      final resultado = await repo.importarMasivo(widget.eventoId, payload);

      if (!mounted) return;

      _mostrarResultado(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => importando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarResultado(Map<String, dynamic> resultado) {
    final importados = resultado['importados'] ?? 0;
    final omitidos = resultado['omitidos'] ?? 0;
    final errores = (resultado['errores'] as List?) ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Resultado de importación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text('$importados importados', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (omitidos > 0) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('$omitidos omitidos'),
              ]),
            ],
            if (errores.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Detalle:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SizedBox(
                height: 150,
                child: ListView(
                  shrinkWrap: true,
                  children: errores.map<Widget>((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('Fila ${e['fila']}: ${e['mensaje']}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Future.microtask(() => Navigator.pop(context, true));
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //
      appBar: AppBar(
        title: const Text('Importar participantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar de nuevo'),
                          onPressed: () {
                            setState(() { error = null; filas = []; });
                            _seleccionarArchivo();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : filas.isEmpty
                  ? const SizedBox()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Icon(Icons.description, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(nombreArchivo, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                              ),
                              Text('${filas.length} filas', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              _buildHeader(),
                              ...filas.map(_buildFila),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        _buildFooter(),
                      ],
                    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Nombre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          SizedBox(width: 80, child: Text('DNI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          SizedBox(width: 40, child: Text('', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFila(_FilaPreview f) {
    final esValida = f.error == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: esValida ? null : Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${f.numero}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
            child: Text(f.nombre, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 80, child: Text(f.dni, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 40,
            child: esValida
                ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                : Icon(Icons.error, color: Colors.red.shade400, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final validas = filas.where((f) => f.error == null).length;
    final invalidas = filas.length - validas;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$validas válidas', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                if (invalidas > 0) ...[
                  const SizedBox(width: 16),
                  Text('$invalidas inválidas', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: importando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload),
                label: Text(importando ? 'Importando...' : 'Importar $validas participantes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: (validas == 0 || importando) ? null : _importar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaPreview {
  final int numero;
  final String nombre;
  final String dni;
  final String correo;
  final String telefono;
  final String? error;

  _FilaPreview({
    required this.numero,
    required this.nombre,
    required this.dni,
    required this.correo,
    required this.telefono,
    this.error,
  });
}
