import "dart:convert";
import "dart:io";
import "dart:typed_data";

String _status = "begin";

const int portRx = 2137;
const int portTx = 2138;

void respond(String destinationAddress) async {
  String serverAddress = "";
  List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false, includeLinkLocal: false);
  for (var _ in interfaces) {
    if (_.name == "wlan0") {
      serverAddress = _.addresses.first.address;
    }
    print("server NIC name:${_.name}, address:${_.addresses.first.address}");
  }

  _status = "responding to broadcast from python";
  print("sending to python @: $destinationAddress:$portTx");

  List<int> data = utf8.encode("hejbvcdjhvb;$serverAddress");
  RawDatagramSocket.bind(InternetAddress.anyIPv4, portRx, reuseAddress: true)
      .then((RawDatagramSocket udpSocket) {
    udpSocket.send(data, InternetAddress(destinationAddress), portTx);
    _status = "responded";
    print(
        "data: ${String.fromCharCodes(data)} sent to python @: ${udpSocket.address.address}");
    udpSocket.close();
    print("close socket waiting for further data from user form python\n");
  });
  startServer(serverAddress);
}

void startServer(String addr) async {
  final server = await ServerSocket.bind(addr, portRx);
  server.listen(
    (client) {
      print("started server for data from client\n");
      handleConnection(client);
    },
    onError: (error) {
      print(error);
      server.close();
    },
    onDone: () {
      print("Server closed");
      server.close();
    },
  );
}

void main() async {
  print("Start of flutter side");
  late var destinationAddress = "";
  RawDatagramSocket.bind(InternetAddress.anyIPv4, portRx)
      .then((RawDatagramSocket udpSocket) {
    udpSocket.broadcastEnabled = true;
    print(
        "adress on which it is litening for broadcast from python ${InternetAddress.anyIPv4.address}");
    udpSocket.listen((e) {
      _status = "waiting for broadcast from python";
      Datagram? dg = udpSocket.receive();
      if (dg != null &&
          String.fromCharCodes(dg.data) == "2930812408yrybce28ufgvb8fy") {
        print(
            "received: ${(String.fromCharCodes(dg.data))}, ${dg.address.address}");
        _status = "received broadcast from python";
        destinationAddress = dg.address.address;
        udpSocket.close();
        respond(destinationAddress);
        return;
      }
    });
  });
}

void handleConnection(Socket client) {
  print("Connection from"
      " ${client.remoteAddress.address}:${client.remotePort}");
  client.listen(
    (Uint8List data) async {
      await Future.delayed(const Duration(seconds: 1), () {
        final message = String.fromCharCodes(data);
        client.write("${message} received.")
      });
    },
    onError: (error) {
      print(error);
      client.close();
    },
    onDone: () {
      print("Client left");
      client.close();
    },
  );
}
