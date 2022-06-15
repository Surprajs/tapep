import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

String convertToPLN(int price) => (price / 100).toStringAsFixed(2);

class Beer {
  final int id;
  int _counter = 0;
  int get counter => _counter;
  final String name;
  final int price;
  Beer(this.id, this.name, this.price);

  void incCounter() {
    _counter++;
  }

  void decCounter() {
    if (_counter > 0) _counter--;
  }
}

final _beers = <Beer>[];
Future<void> readJson() async {
  await rootBundle
      .loadString('assets/list_of_beers.json')
      .then(json.decode)
      .then((data) => data["beers"])
      .then((list) =>
          list.map((item) => Beer(item["id"], item["name"], item["price"])))
      .then((list) => list.forEach(_beers.add));
}

class Order {
  final _beers = <String, int>{};
  Map<String, int> get beers => _beers;
  int _totalPrice = 0;
  int get totalPrice => _totalPrice;
  Order();
  Map toJson() => {
        "order": _beers.toString(),
        "price": _totalPrice,
      };
  void addBeer(Beer beer) {
    if (beer.counter > 0) {
      beers.addAll({beer.name: beer.counter});
      _totalPrice += beer.price;
    }
  }

  void removeBeer(Beer beer) {
    if (beers.containsKey(beer.name) && beer.counter == 0) {
      beers.remove(beer.name);
      _totalPrice -= beer.price;
    } else if (beer.counter > 0) {
      beers.addAll({beer.name: beer.counter});
      _totalPrice -= beer.price;
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  readJson();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "poley.me",
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const OrderedBeers(),
    );
  }
}

class OrderedBeersState extends State<OrderedBeers> {
  final Order _order = Order();
  String _jsonOrder = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("poley.me"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: _order.beers.isEmpty ? null : _pushOrder,
            tooltip:
                _order.beers.isEmpty ? "Order is empty" : "Generate QR Code",
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _beers.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(
            _beers[i].name,
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
          subtitle: Text(
            "${convertToPLN(_beers[i].price)} PLN",
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          trailing: SizedBox(
            width: 100,
            child: Row(
              children: [
                InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                    onTap: () {
                      setState(() {
                        _beers[i].decCounter();
                        _order.removeBeer(_beers[i]);
                      });
                    },
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: _beers[i].counter > 0
                          ? Colors.black
                          : Colors.grey.shade400,
                      size: 30,
                    )),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: Text(
                    _beers[i].counter.toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 40),
                  ),
                ),
                InkWell(
                    onTap: () {
                      setState(() {
                        _beers[i].incCounter();
                        _order.addBeer(_beers[i]);
                      });
                    },
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.black,
                      size: 30,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pushOrder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          _jsonOrder = jsonEncode(_order);
          return Scaffold(
            appBar: AppBar(
              title: const Text("Current order"),
            ),
            body: Column(
              children: [
                Center(
                  child: QrImage(
                    data: _jsonOrder,
                    version: QrVersions.auto,
                    size: 320,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text:
                          "Total Price: ${convertToPLN(_order.totalPrice)} PLN\nDetails of the order:\n",
                      style: const TextStyle(fontSize: 25, color: Colors.black),
                      children: _order.beers.entries.map((entry) {
                        String line = "${entry.value}x ${entry.key}\n";
                        return TextSpan(text: line);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderedBeers extends StatefulWidget {
  const OrderedBeers({super.key});
  @override
  State<OrderedBeers> createState() => OrderedBeersState();
}

