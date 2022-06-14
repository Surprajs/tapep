import socket
import netifaces as ni
from time import sleep
from ipaddress import ip_network as ipn

port_rx = 2138
port_tx = 2137

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
ip_wifi = ni.ifaddresses('wifi0')[ni.AF_INET][0]['addr']
mask_wifi = ni.ifaddresses('wifi0')[ni.AF_INET][0]['netmask']
# ip_wifi = "192.168.1.13"
# mask_wifi = "255.255.255.0"
net_addr = ipn(ip_wifi + "/" + mask_wifi, strict=False)
print("net addr:", net_addr.network_address)
broadcast_addr = str(net_addr.network_address).replace("0", "255")
print("ip from netiface: ", ip_wifi, ",mask: ", mask_wifi)
flutter = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
flutter.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
flutter.bind((ip_wifi, port_rx))
flutter.settimeout(1)

msg = b'2930812408yrybce28ufgvb8fy'
msg_conn_established = b'disbhcovdvoewubwu'


def connect():
	while True:
		sock.sendto(msg, (broadcast_addr, port_tx))
		try:
			data = flutter.recv(64).decode("UTF-8")
			if data.__contains__('hejbvcdjhvb'):
				ip_serv = data.split(";")[1]
				print("data received:", data,  ",device@: ", ip_wifi)
				# sock.sendto(b'disbhcovdvoewubwu', (ip_wifi, port_rx)) # confirmation from python to flutter
				break
		except socket.error as socketerror:
			print("Error: ", socketerror)
		sleep(2)
	print("success")
	return ip_serv

def main():
	ip_serv = connect()
	while True:
		# usr_input = input("provide string:")
		# print(usr_input)
		# new = usr_input.encode(encoding="UTF-8")
		# sock.sendto(new , (flutter_address, port_tx))
		# sleep(2)
		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
			server_address = (ip_serv, port_tx)
			print('Connecting to %s port %s' % server_address)
			s.connect(server_address)
			try:

				while True:
					msg = input("Enter msg:")
					if len(msg) > 0:
						s.sendall(msg.encode('UTF-8'))
					data = s.recv(64)
					print('received "%s"' % data.decode("UTF-8"))
			finally:
				print('closing socket')
				s.sendall(b'EXIT')
				s.close()
				
main()


main()
