"""Compile/inspect only this project inside the dedicated Docker image."""
import os
import subprocess
import sys
from pathlib import Path

B=Path(__file__).resolve().parent
image='cpu-report-tex:v7-20261026'
args=['docker','run','--rm','--name','cpu-report-tex-compile',
      '--label','task=cpu-report-latex','--network','none',
      '--cpus','1','--memory','2g','--memory-swap','2g','--pids-limit','256',
      '--cap-drop','ALL','--security-opt','no-new-privileges',
      '--read-only','--tmpfs','/tmp:rw,nosuid,size=256m',
      '--user',f'{os.getuid()}:{os.getgid()}',
      '--mount',f'type=bind,src={B},dst=/work',
      '--workdir','/work','--env','HOME=/tmp',image]
command=sys.argv[1:] or ['python3','build.py']
raise SystemExit(subprocess.run(args+command).returncode)
