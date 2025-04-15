#!/usr/bin/env python3

import argparse
import paramiko
import os
import time

def run_remote_script(
    hostname,
    port,
    username,
    key_file_path,
    new_bitfile_path=""
):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    key_file_path = os.path.expanduser(key_file_path)

    client.connect(
        hostname,
        port=port,
        username=username,
        key_filename=key_file_path,
        look_for_keys=False,
        allow_agent=False
    )

    remote_basedir = "/home/xilinx/cheshire/"
    if new_bitfile_path != "":
        sftp = client.open_sftp()
        sftp.put(new_bitfile_path, remote_basedir + "bitfile/cheshire.bit")
        sftp.close()

    channel = client.invoke_shell()
    time.sleep(1)

    
    cmd = f"python3 {remote_basedir}scripts/load_bitfile.py\n"
    channel.send(cmd)
    #channel.send("echo ciao")
    time.sleep(1)

def main():
    
    parser = argparse.ArgumentParser(
        description="Run a remote Python script under root privileges over SSH with key-based auth."
    )
    parser.add_argument("--host", default="192.168.5.10",                                help="Hostname or IP of the remote machine.")
    parser.add_argument("--port", type=int, default=22,                         help="SSH port. Default is 22.")
    parser.add_argument("--user", default="root",                             help="SSH username on the remote machine.")
    parser.add_argument("--key", default="~/.ssh/rsa_pynqs",                       help="Path to the SSH private key file.")
    
    parser.add_argument("--bitfile", default="",   help="Base directory on the remote machine.")

    args = parser.parse_args()

    run_remote_script(
        hostname=args.host,
        port=args.port,
        username=args.user,
        key_file_path=args.key,
        new_bitfile_path=args.bitfile
    )
