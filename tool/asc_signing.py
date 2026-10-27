#!/usr/bin/env python3
"""Signature App Store éphémère via l'API App Store Connect.

  setup   crée une clé privée, un certificat « Apple Distribution » et un
          profil App Store pour le bundle ; écrit le .p12 et le profil, et
          ajoute leurs références à $GITHUB_ENV.
  cleanup révoque le certificat et supprime le profil créés par setup.

Variables : KEY_ID, ISSUER_ID, KEY_PATH (fichier .p8), BUNDLE_ID, OUT_DIR,
P12_PASSWORD ; pour cleanup : ASC_CERT_ID, ASC_PROFILE_ID.
Dépendances : pyjwt, cryptography.
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

API = 'https://api.appstoreconnect.apple.com/v1'


def token() -> str:
    key = open(os.environ['KEY_PATH'], encoding='utf-8').read()
    now = int(time.time())
    return jwt.encode(
        {'iss': os.environ['ISSUER_ID'], 'iat': now, 'exp': now + 900,
         'aud': 'appstoreconnect-v1'},
        key,
        algorithm='ES256',
        headers={'kid': os.environ['KEY_ID'], 'typ': 'JWT'},
    )


def call(method: str, path: str, body=None):
    req = urllib.request.Request(
        API + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': f'Bearer {token()}',
                 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors='replace')
        sys.exit(f'::error::App Store Connect {method} {path} : {e.code} {detail}')


def env_out(**kv):
    path = os.environ.get('GITHUB_ENV')
    for k, v in kv.items():
        print(f'{k}={v}')
        if path:
            with open(path, 'a', encoding='utf-8') as f:
                f.write(f'{k}={v}\n')


def setup():
    bundle = os.environ['BUNDLE_ID']
    out = os.environ['OUT_DIR']
    password = os.environ['P12_PASSWORD'].encode()
    os.makedirs(out, exist_ok=True)

    # 1. Identifiant du bundle enregistré.
    q = urllib.parse.urlencode({'filter[identifier]': bundle})
    ids = [b for b in call('GET', f'/bundleIds?{q}')['data']
           if b['attributes']['identifier'] == bundle]
    if not ids:
        sys.exit(f'::error::Identifiant {bundle} introuvable : enregistrez-le '
                 'dans developer.apple.com › Identifiers.')
    bundle_rid = ids[0]['id']

    # 2. Clé privée et demande de certificat.
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (x509.CertificateSigningRequestBuilder()
           .subject_name(x509.Name([
               x509.NameAttribute(NameOID.COMMON_NAME, 'CliniFlow CI'),
               x509.NameAttribute(NameOID.COUNTRY_NAME, 'FR'),
           ]))
           .sign(key, hashes.SHA256()))
    csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode()

    # 3. Certificat Apple Distribution.
    cert = call('POST', '/certificates', {'data': {
        'type': 'certificates',
        'attributes': {'certificateType': 'DISTRIBUTION', 'csrContent': csr_pem},
    }})['data']
    cert_id = cert['id']
    env_out(ASC_CERT_ID=cert_id)
    der = base64.b64decode(cert['attributes']['certificateContent'])
    certificate = x509.load_der_x509_certificate(der)

    # 4. Profil App Store lié au certificat.
    name = f'CliniFlow CI {int(time.time())}'
    prof = call('POST', '/profiles', {'data': {
        'type': 'profiles',
        'attributes': {'name': name, 'profileType': 'IOS_APP_STORE'},
        'relationships': {
            'bundleId': {'data': {'type': 'bundleIds', 'id': bundle_rid}},
            'certificates': {'data': [{'type': 'certificates', 'id': cert_id}]},
        },
    }})['data']
    env_out(ASC_PROFILE_ID=prof['id'], ASC_PROFILE_NAME=name)
    profile_path = os.path.join(out, 'appstore.mobileprovision')
    with open(profile_path, 'wb') as f:
        f.write(base64.b64decode(prof['attributes']['profileContent']))
    env_out(ASC_PROFILE_UUID=prof['attributes']['uuid'],
            ASC_PROFILE_PATH=profile_path)

    # 5. .p12 compatible avec le trousseau macOS.
    enc = (serialization.PrivateFormat.PKCS12.encryption_builder()
           .kdf_rounds(50000)
           .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC)
           .hmac_hash(hashes.SHA1())
           .build(password))
    p12 = pkcs12.serialize_key_and_certificates(
        b'CliniFlow CI', key, certificate, None, enc)
    p12_path = os.path.join(out, 'dist.p12')
    with open(p12_path, 'wb') as f:
        f.write(p12)
    env_out(ASC_P12_PATH=p12_path)


def cleanup():
    pid = os.environ.get('ASC_PROFILE_ID')
    cid = os.environ.get('ASC_CERT_ID')
    if pid:
        call('DELETE', f'/profiles/{pid}')
        print('profil supprimé')
    if cid:
        call('DELETE', f'/certificates/{cid}')
        print('certificat révoqué')


if __name__ == '__main__':
    {'setup': setup, 'cleanup': cleanup}[sys.argv[1]]()
