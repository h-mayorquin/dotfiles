#!/usr/bin/env -S uv run --script
"""Decode a Gmail API message response from stdin and print it as plain text."""
import json, sys, base64

d = json.load(sys.stdin)
headers = {h['name']: h['value'] for h in d['payload']['headers']}
print('From:', headers.get('From'))
print('Subject:', headers.get('Subject'))
print('Date:', headers.get('Date'))
print()

def get_body(p):
    if p.get('body', {}).get('data'):
        return base64.urlsafe_b64decode(p['body']['data']).decode('utf-8', errors='replace')
    for part in p.get('parts', []):
        if part['mimeType'] in ('text/plain', 'text/html'):
            if part.get('body', {}).get('data'):
                return base64.urlsafe_b64decode(part['body']['data']).decode('utf-8', errors='replace')
        for sub in part.get('parts', []):
            if sub['mimeType'] == 'text/plain' and sub.get('body', {}).get('data'):
                return base64.urlsafe_b64decode(sub['body']['data']).decode('utf-8', errors='replace')
    return ''

print(get_body(d['payload']))
