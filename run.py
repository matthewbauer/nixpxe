#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nix pixiecore python3

import argparse
import os
import time
import subprocess
import http.server
import json

port = 4242
configFile = "./config.json"

parser = argparse.ArgumentParser(description='Run NixOS PXE Daemon')
parser.add_argument('config', type=str, help='config file',
                    default='./config.json', nargs='?')

args = parser.parse_args()

if not os.path.exists(args.config):
    print("Config %s does not exist" % args.config)
    sys.exit(1)

knownAddresses = {}
numHosts = 1

def build_system(attr, mac_address):
    global numHosts
    process = subprocess.Popen(['nix-build', '--no-gc-warning', '--no-out-link', 'system.nix',
                                '--option', 'experimental-features', 'recursive-nix',
                                '-A', attr,
                                "--argstr", "macAddress", mac_address,
                                "--argstr", "hostName", "nixos%s" % numHosts,
                                "--arg", "config", ("builtins.fromJSON (builtins.readFile %s)" % args.config)]
                                , stdout=subprocess.PIPE)
    if mac_address not in knownAddresses:
        knownAddresses[mac_address] = True
        numHosts += 1
    return process

class PixieListener(http.server.BaseHTTPRequestHandler):
    def do_nix_GET(self, attr, path):
        parts = self.path.split('/')
        mac_address = parts[2]
        process = build_system(attr, mac_address)
        drv = None
        timeout = 0
        while True:
            drv = process.stdout.readline().decode("utf-8").rstrip()
            if drv != '':
                break
            elif not process.returncode or process.returncode > 0:
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
        filename = drv + path
        self.send_header('Content-Length', "%s" % os.path.getsize(filename))
        self.end_headers()
        with open(filename, 'rb') as f:
            self.wfile.write(f.read())

    def do_GET(self):
        parts = self.path.split('/')
        if parts[1] == 'v1' and parts[2] == 'boot':
            mac_address = parts[3]
            process = build_system('config.system.build.toplevel', mac_address)
            system = None
            timeout = 0
            while True:
                system = process.stdout.readline().decode("utf-8").rstrip()
                if system != '':
                    break
                elif not process.returncode or process.returncode > 0:
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

process = subprocess.Popen(["pixiecore", "api", "--api-request-timeout", "15m", "http://localhost:%s" % port])

httpd = http.server.HTTPServer(('', port), PixieListener)
while not process.poll():
    httpd.handle_request()
