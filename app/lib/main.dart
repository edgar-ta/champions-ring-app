import 'package:flutter/material.dart';

void main() => runApp(const appRING());

class appRING extends StatelessWidget {
  const appRING({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Champions Ring',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd8a62a)), useMaterial3: true),
    home: const InicioDeLaCosa(title: 'CHAMPIONS RING'),
  );
}

class InicioDeLaCosa extends StatefulWidget {
  const InicioDeLaCosa({super.key, required this.title});
  final String title;

  @override
  State<InicioDeLaCosa> createState() => _Pantalla_que_no_deberia_ser_tan_grande();
}

class _Pantalla_que_no_deberia_ser_tan_grande extends State<InicioDeLaCosa> {
  int _counter = 0;
  int cosa = 0;
  bool mostrarTodo = true;
  final List<String> _peleas = ['A. Silva vs. M. Cruz', 'L. Vega vs. R. Torres', 'N. Díaz vs. P. León'];

  void _incrementCounter() {
    setState(() {
      _counter++;
      cosa = cosa == 2 ? 0 : cosa + 1;
      if (_counter % 4 == 0) { mostrarTodo = !mostrarTodo; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xff101116),
      appBar: AppBar(
        backgroundColor: const Color(0xff171920),
        foregroundColor: Colors.white,
        title: Row(children: [const Icon(Icons.sports_mma, color: Color(0xffe1b443)), const SizedBox(width: 9), Text(widget.title)]),
        actions: [IconButton(onPressed: () { setState(() { mostrarTodo = !mostrarTodo; }); }, icon: Icon(mostrarTodo ? Icons.notifications_active : Icons.notifications_off))],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xff35301f), Color(0xff191a20)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xff75602e))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SÁBADO · 20:00', style: TextStyle(color: Color(0xffe1b443), fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 12),
                const Text('NOCHE DE\nCAMPEONES', style: TextStyle(color: Colors.white, fontSize:  thirty, height: 1.05, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Text('El octágono te espera. Vive cada combate.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: () { setState(() { cosa = cosa + 1; }); }, icon: const Icon(Icons.confirmation_num_outlined), label: Text(cosa > 0 ? 'RESERVAR · $cosa' : 'RESERVAR BOLETOS')),
              ]),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('PRÓXIMOS COMBATES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)), Text(mostrarTodo ? 'VER TODO' : 'FILTRADO', style: TextStyle(color: color.primary))]),
            const SizedBox(height: 10),
            for (var i = 0; i < (mostrarTodo ? _peleas.length : 1); i++)
              Card(color: const Color(0xff1c1e25), child: ListTile(leading: CircleAvatar(backgroundColor: i == cosa ? const Color(0xffe1b443) : const Color(0xff30333c), child: Icon(i == cosa ? Icons.bolt : Icons.sports_mma, color: Colors.white)), title: Text(_peleas[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), subtitle: Text(i == 0 ? 'PESO WÉLTER · PELEA ESTELAR' : i == 1 ? 'PESO LIGERO · SEMIFINAL' : 'PESO PLUMA · PRELIMINAR', style: const TextStyle(color: Colors.white54, fontSize: 10)), trailing: Text(i == 0 ? '20:00' : i == 1 ? '19:15' : '18:30', style: const TextStyle(color: Color(0xffe1b443)))),),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xff1c1e25), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.local_fire_department, color: Color(0xffe1b443), size: 32), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TU RACHA DE FAN', style: TextStyle(color: Colors.white70, fontSize: 11)), Text('$_counter', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text('noches siguiendo la acción', style: TextStyle(color: Colors.white54))])), IconButton(onPressed: _incrementCounter, icon: const Icon(Icons.add_circle, color: Color(0xffe1b443), size: 30))])),
            const SizedBox(height: 18),
            Center(child: Text(cosa == 0 ? 'EL RING ESTÁ LISTO' : cosa == 1 ? '¡QUE COMIENCE EL SHOW!' : 'CAMPEONES SE HACEN AQUÍ', style: const TextStyle(color: Colors.white38, letterSpacing: 1, fontSize: 11))),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _incrementCounter, tooltip: 'Increment', child: const Icon(Icons.add)),
    );
  }
}

const double thirty = 30;
