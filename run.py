#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nixUnstable pixiecore python3

import argparse
import os
import time
import subprocess
import http.server
import json
import sys
import tempfile

port = 4242

parser = argparse.ArgumentParser(description='Run NixOS PXE Daemon')
parser.add_argument('flake', type=str, help='flake file',
                    default='./template', nargs='?')

args = parser.parse_args()

if not os.path.exists(args.flake):
    print("Flake %s does not exist" % args.flake)
    sys.exit(1)

def build_system(attr, mac_address):
    path = None
    tmp = tempfile.mkdtemp() + '/result'
    try:
        # FIXME: should validate mac address
        process = subprocess.Popen(['nix', '--experimental-features', 'nix-command flakes recursive-nix', 'build', "-o", tmp, "%s#nixosConfigurations.%s.%s" % (args.flake, mac_address, attr)])
        process.wait()
        path = os.readlink(tmp)
    finally:
        os.unlink(tmp)
    return path

class PixieListener(http.server.BaseHTTPRequestHandler):
    def do_nix_GET(self, attr, path):
        parts = self.path.split('/')
        mac_address = parts[2]
        drv = build_system(attr, mac_address)
        self.send_response(200)
        filename = drv + path
        self.send_header('Content-Length', "%s" % os.path.getsize(filename))
        self.end_headers()
        with open(filename, 'rb') as f:
            self.wfile.write(f.read())

    def do_GET(self):
        parts = self.path.split('/')
        if parts[1] == 'v1' and parts[2] == 'boot':
            mac_address = parts[3]
            system = build_system('config.system.build.toplevel', mac_address)
            kernel_params = ''
            with open('%s/kernel-params' % system, 'r') as f:
                kernel_params = f.read()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "kernel": "/kernel/%s" % mac_address,
                "initrd": ["/initrd/%s" % mac_address, "/nix-store/%s" % mac_address, "/manifest/%s" % mac_address],
                "cmdline": ("init=%s/init %s" % (system, kernel_params))
            }).encode())
        elif parts[1] == 'kernel':
            self.do_nix_GET('config.system.build.kernel', '/bzImage')
        elif parts[1] == 'initrd':
            self.do_nix_GET('config.system.build.initialRamdisk', '/initrd')
        elif parts[1] == 'manifest':
            self.do_nix_GET('config.system.build.manifestRamdisk', '/initrd')
        elif parts[1] == 'nix-store':
            self.do_nix_GET('config.system.build.nixStoreRamdisk', '/initrd')
        else:
            self.send_response(404)
            self.end_headers()

process = subprocess.Popen(["sudo", "pixiecore", "api", "--api-request-timeout", "15m", "http://localhost:%s" % port])

httpd = http.server.HTTPServer(('', port), PixieListener)
print("Serving on %s" % port)
while not process.poll():
    httpd.handle_request()
