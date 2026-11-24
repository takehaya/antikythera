"""Compile with an already installed Japanese TeX system; never install anything."""
import shutil
import subprocess
from pathlib import Path

B=Path(__file__).resolve().parent
required=['platex','pbibtex','dvipdfmx','extractbb']
missing=[name for name in required if not shutil.which(name)]
if missing:
    raise SystemExit('Missing existing tools: '+', '.join(missing)+'. No installation was attempted.')
(B/'build').mkdir(exist_ok=True)
commands=[['extractbb',str(p.relative_to(B))] for p in sorted((B/'figures').glob('*.png'))]
commands += [['platex','-kanji=utf8','-no-shell-escape','-interaction=nonstopmode','-halt-on-error','-file-line-error','-output-directory=build','main.tex'],
          ['pbibtex','-kanji=utf8','build/main'],
          ['platex','-kanji=utf8','-no-shell-escape','-interaction=nonstopmode','-halt-on-error','-file-line-error','-output-directory=build','main.tex'],
          ['platex','-kanji=utf8','-no-shell-escape','-interaction=nonstopmode','-halt-on-error','-file-line-error','-output-directory=build','main.tex'],
          ['dvipdfmx','-o','build/main-dvipdfmx.pdf','build/main.dvi'],
          ['python3','embed_japanese_unicode.py','build/main-dvipdfmx.pdf','build/main.pdf']]
with (B/'build/commands.log').open('w') as log:
    for cmd in commands:
        log.write('$ '+' '.join(cmd)+'\n');log.flush()
        subprocess.run(cmd,cwd=B,stdout=log,stderr=subprocess.STDOUT,check=True)
print('Compiled build/main.pdf. Font, extraction, references and visual QA are still required.')
