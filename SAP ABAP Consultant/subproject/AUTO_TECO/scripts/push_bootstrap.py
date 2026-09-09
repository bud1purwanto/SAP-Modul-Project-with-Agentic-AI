import json, re, sys
from string import Template

# Baca source yang sudah dipatch
with open('src/ZPPI_COHVPI.abap') as f:
    patched_source = f.read()

lines = patched_source.splitlines()

# Batas baris ABAP untuk INSERT REPORT adalah 255 (atau bisa juga kita belah jika lebih panjang)
# Karena ZPPI_COHVPI punya 1600 baris, bootstrap program via RFC_ABAP_INSTALL_AND_RUN
# tidak efisien dan rentan error jika kita hardcode 1600 baris x 255 char di dalam 72 char.
#
# Sebenarnya ada cara lebih baik dengan Python. Saya panggil RPY_PROGRAM_UPDATE saja.
print("Kita buat payload JSON untuk RPY_PROGRAM_UPDATE")

it_source = [{"LINE": line} for line in lines]
payload = {
  "function_name": "Z_RFC_PROGRAM_UPDATE",
  "parameters": {
    "IV_PROGRAM_NAME": "ZPPI_COHVPI",
    "IV_PACKAGE": "$TMP",
    "IV_CORRNUMBER": " ",
    "IT_SOURCE": it_source
  }
}
with open('rpy_payload.json', 'w') as out:
    json.dump(payload, out)

