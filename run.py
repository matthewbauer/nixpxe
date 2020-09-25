#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nix pixiecore python3

import subprocess
import http.server.BaseHTTPServer

port = 4242
authorizedKey = ''
configFile = "./config.json"

def build_system(attr):
    process = subprocess.Popen(['nix-build', '--no-gc-warning', '--no-out-link', 'system.nix', '-A', attr, "--arg", "config", ("builtins.fromJSON (builtins.readFile %s)" % configFile)]
                           , stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result, stderr = process.communicate()
    return result

pxe_ramdisk = build_system('config.system.build.netbootRamdisk')
pxe_kernel = build_system('config.system.build.kernel')
system = build_system('config.system.build.toplevel')

kernel_params = ''
with open('%s/kernel-params', 'r') as f:
    kernel_params = f.read()

class PixieListener(http.server.BaseHTTPServer.BaseHTTPRequestHandler):
    def do_GET(self):
        parts = self.path.split('/')
        if parts[1] == 'v1' and parts[2] == 'boot':
            mac_address = parts[3]
            self.send_response(200)
v            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "kernel": "/kernel",
                "initrd": ["/initrd"],
                "cmdline": ("init=%s/init %s" % (system, kernel_params))
            }).encode())
        elif parts[1] == 'shutdown':
            mac_address = parts[3]
            self.send_response(200)
            self.end_headers()
        elif parts[1] == 'kernel':
            self.send_response(200)
            self.end_headers()
            with open('%s/bzImage' % pxe_kernel, 'rb') as f:
                self.wfile.write(f.read())
        elif parts[1] == 'initrd':
            self.send_response(200)
            self.end_headers()
            with open('%s/initrd' % pxe_ramdisk, 'rb') as f:
                self.wfile.write(f.read())
        else:
            self.send_response(404)
            self.end_headers()

http.server.BaseHTTPServer.HTTPServer(('', port), PixieListener).serve_forever()
