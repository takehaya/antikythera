"""Rebuild the isolated TeX image with explicit CPU/memory limits.

Downloads only the official Debian base and Debian packages. No project source
or host mount is given to the network-enabled installation container.
"""
import subprocess
from pathlib import Path

B=Path(__file__).resolve().parent
base='debian@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8'
name='cpu-report-tex-v7-builder-20261026'
image='cpu-report-tex:v7-20261026'
def run(args):subprocess.run(args,check=True)
run(['docker','pull','--platform','linux/arm64',base])
run(['docker','run','-d','--name',name,'--label','task=cpu-report-latex-v7',
     '--platform','linux/arm64','--cpus','1','--memory','2g','--memory-swap','2g',
     '--pids-limit','256','--security-opt','no-new-privileges',base,'sleep','infinity'])
try:
    run(['docker','cp',str(B/'install-tex.sh'),name+':/tmp/install-tex.sh'])
    run(['docker','exec',name,'sh','/tmp/install-tex.sh'])
    run(['docker','commit','--change','WORKDIR /work','--change','ENV HOME=/tmp',
         '--change','CMD ["python3", "build.py"]',name,image])
finally:
    # Only the container created above is eligible for removal.
    run(['docker','rm','-f',name])
