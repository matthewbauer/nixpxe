#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nix pixiecore python3

import subprocess
import http.server

port = 4242
authorizedKey = ''
configFile = "./config.json"

def build_system(attr, mac_address):
    return subprocess.Popen(['nix-build', '--no-gc-warning', '--no-out-link', 'system.nix',
                             '-A', attr,
                             "--arg", "config", ("builtins.fromJSON (builtins.readFile %s)" % configFile)]
                            , stdout=subprocess.PIPE)

class PixieListener(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parts = self.path.split('/')
        if parts[1] == 'v1' and parts[2] == 'boot':
            mac_address = parts[3]
            process = build_system('config.system.build.toplevel', mac_address)
            system = None
            timeout = 0
            while True:
                system = process.stdout.readline()
                if system != '' and process.poll():
                    if process.returncode != 0:
                        self.send_response(500)
                        self.end_headers()
                        return
                    break
                elif process.poll():
                    self.send_response(500)
                    self.end_headers()
                    return
                elif timeout > 500:
                    self.send_response(500)
                    self.end_headers()
                    return
                timeout += 1
                time.sleep(1)
            kernel_params = ''
            with open('%s/kernel-params', 'r') as f:
                kernel_params = f.read()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "kernel": "/kernel/%s" % mac_address,
                "initrd": ["/initrd/%s" % mac_address],
                "cmdline": ("init=%s/init %s" % (system, kernel_params))
            }).encode())
        elif parts[1] == 'kernel':
            mac_address = parts[2]
            process = build_system('config.system.build.kernel', mac_address)
            pxe_kernel = None
            timeout = 0
            while True:
                pxe_kernel = process.stdout.readline()
                if pxe_kernel != '' and process.poll():
                    if process.returncode != 0:
                        self.send_response(500)
                        self.end_headers()
                        return
                    break
                elif process.poll():
                    self.send_response(500)
                    self.end_headers()
                    return
                elif timeout > 500:
                    self.send_response(500)
                    self.end_headers()
                    return
                timeout += 1
                time.sleep(1)
            self.send_response(200)
            self.end_headers()
            with open('%s/bzImage' % pxe_kernel, 'rb') as f:
                self.wfile.write(f.read())
        elif parts[1] == 'initrd':
            mac_address = parts[2]
            process = build_system('config.system.build.netbootRamdisk', mac_address)
            pxe_ramdisk = None
            timeout = 0
            while True:
                pxe_ramdisk = process.stdout.readline()
                if pxe_ramdisk != '' and process.poll():
                    if process.returncode != 0:
                        self.send_response(500)
                        self.end_headers()
                        return
                    break
                elif process.poll():
                    self.send_response(500)
                    self.end_headers()
                    return
                elif timeout > 500:
                    self.send_response(500)
                    self.end_headers()
                    return
                timeout += 1
                time.sleep(1)
            self.send_response(200)
            self.end_headers()
            with open('%s/initrd' % pxe_ramdisk, 'rb') as f:
                self.wfile.write(f.read())
        else:
            self.send_response(404)
            self.end_headers()

process = subprocess.Popen(["pixiecore", "api", "http://localhost:4242"])

httpd = http.server.HTTPServer(('', port), PixieListener)
while not process.poll():
    httpd.handle_request()
