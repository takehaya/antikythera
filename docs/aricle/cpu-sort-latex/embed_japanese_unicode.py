"""Make the embedded Japanese fonts self-describing without outlining text.

Input must be this report's dvipdfmx output: horizontal Identity-H Type0 fonts
whose descendants use Adobe-Japan1. The complete, unmodified Adobe CMap is
bundled with its copyright/license notice. Page content and font programs are
not altered. This is a reproducible final step of the LaTeX build.
"""
import sys
from pathlib import Path
import pikepdf

root=Path(__file__).resolve().parent
cmap_bytes=(root/'fonts/Adobe-Japan1-UCS2').read_bytes()
src,out=map(Path,sys.argv[1:])
assert src.resolve()!=out.resolve()
pdf=pikepdf.open(src)
cmap=pdf.make_stream(cmap_bytes)
seen=set();changed=[]
for page in pdf.pages:
    for _,font in page.Resources.get('/Font',{}).items():
        if font.objgen in seen:continue
        seen.add(font.objgen)
        if font.get('/Subtype') != pikepdf.Name('/Type0'):continue
        name=str(font.BaseFont)
        assert 'IPAexMincho' in name or 'IPAexGothic' in name, name
        desc=font.DescendantFonts[0];csi=desc.CIDSystemInfo
        assert font.Encoding==pikepdf.Name('/Identity-H')
        assert str(csi.Registry)=='Adobe' and str(csi.Ordering)=='Japan1'
        assert desc.Subtype==pikepdf.Name('/CIDFontType2')
        assert desc.CIDToGIDMap==pikepdf.Name('/Identity')
        assert '/FontFile2' in desc.FontDescriptor
        assert '/ToUnicode' not in font
        font.ToUnicode=cmap
        changed.append(name)
assert len(changed)==2,changed
pdf.save(out)
print('Embedded Adobe-Japan1-UCS2 ToUnicode for:',', '.join(changed))
