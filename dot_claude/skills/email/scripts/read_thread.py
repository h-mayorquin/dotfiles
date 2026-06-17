#!/usr/bin/env -S uv run --script
"""Print a summary of all messages in a Gmail thread from stdin."""
import json, sys

d = json.load(sys.stdin)
messages = d.get("messages", [])
print(f"Thread: {len(messages)} messages")
for msg in messages:
    h = {x["name"]: x["value"] for x in msg["payload"]["headers"]}
    print(f"  {h.get('Date','')[:25]} | {h.get('From','')[:35]} | {h.get('Subject','')[:50]}")
