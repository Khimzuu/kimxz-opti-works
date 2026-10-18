"""Static consistency checks; intentionally does not execute Windows system changes."""
from pathlib import Path
import re, unittest
ROOT=Path(__file__).resolve().parents[1]
class TestWiring(unittest.TestCase):
 def test_buttons_host(self):
  frontend=(ROOT/'frontend/app.js').read_text()
  host=(ROOT/'src/KimXZ.OptiWorks/Program.cs').read_text()
  ids=set(re.findall(r"id:'([^']+)'",frontend))
  implemented=set(re.findall(r'\["([^"\]]+)"\]=',host))
  self.assertTrue(ids <= implemented, f'UI operations missing: {ids-implemented}')
 def test_host_backend(self):
  host=(ROOT/'src/KimXZ.OptiWorks/Program.cs').read_text()
  backend=(ROOT/'backend/worker.ps1').read_text()
  ops=set(re.findall(r'new\[\]\{([^}]+)\}',host))
  selected=set(re.findall(r'"([\w-]+)"',','.join(ops)))
  allowed=set(re.findall(r"'([\w-]+)'",backend.split('$allowed=@(',1)[1].split(')',1)[0]))
  self.assertFalse(selected-allowed, f'Backend operations missing: {selected-allowed}')
 def test_no_security_bypass(self):
  code=(ROOT/'backend/worker.ps1').read_text().lower()
  for phrase in ('set-mppreference','disableantispyware','wuauserv','tamperprotection','bcdedit','stop-service'):
   self.assertNotIn(phrase,code)
 def test_relative_launcher(self):
  code=(ROOT/'Launch-kim.xz.bat').read_text().lower()
  self.assertIn('get-filehash',code)
  self.assertIn('raw.githubusercontent.com/khimzuu/kimxz-opti-works',code)
  self.assertIn('dotnet build',code)
if __name__=='__main__':unittest.main()
