#!/usr/bin/env python3

from collections import defaultdict
from dataclasses import dataclass
from jira import JIRA
from jira.resources import PropertyHolder
import argparse
import csv
import os


parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
    ./automate.py cids.csv
""")

if os.getenv("JIRA_EMAIL") is None:
    parser.add_argument("--email", help="Jira Email", required=True)
if os.getenv("JIRA_TOKEN") is None:
    parser.add_argument("--token", help="Jira Token", required=True)
parser.add_argument("cids", help="CSV file containing CIDs")

args = parser.parse_args()


class CID:
    def __init__(self, cid):
        self.cid = cid

    def add_info(self, lab_room, frame, shief, partition, blocker, provision_method, c3):
        self.lab_room = lab_room
        self.frame = frame
        self.shief = shief
        self.partition = partition
        self.blocker = blocker
        self.provision_method = provision_method
        self.c3 = c3


cids = defaultdict(CID)

with open(args.cids) as f:
    reader = csv.reader(f)
    headers = next(reader)
    for row in reader:
        cid = row[4]
        if cid.startswith('202'):
            cid = CID(row[4])
            cid.add_info(row[0], row[1], row[2], row[3], row[5], row[6], row[7])
            cids[row[4]] = cid

jira = JIRA(
    server="https://warthogs.atlassian.net",
    basic_auth=(
        os.getenv("JIRA_EMAIL") if os.getenv("JIRA_EMAIL") else args.email,
        os.getenv("JIRA_TOKEN") if os.getenv("JIRA_TOKEN") else args.token)
)
jira._options.update({"rest_api_version": 3})


@dataclass
class SomePrefix(str):
    string: str

    def __eq__(self, other):
        return self.string.startswith(other)


def adf_dump(obj):
    if not isinstance(obj, PropertyHolder):
        raise Exception("Unknown type: " + str(obj) + " " + str(dir(obj)))
    data = {}
    for key in dir(obj):
        if key == 'content':
            data[key] = []
            for part in obj.content:
                data[key].append(adf_dump(part))
        elif key == 'marks':
            data[key] = []
            for mark in obj.marks:
                data[key].append(adf_dump(mark))
        elif key == 'attrs':
            data[key] = {}
            for attr in dir(obj.attrs):
                if attr[0] == '_':
                    continue
                data[key][attr] = getattr(obj.attrs, attr)
        elif key[0] != '_':
            data[key] = getattr(obj, key)
    return data


def update_issue(cid, dut) -> bool:
    network_status = "connected" if dut.blocker.lower() == "connected" else "disconnected"
    status = "To Do: Cert Lab"
    if issue.fields.summary != f"[Backlog] {dut.cid}":
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} is not a backlog issue. Skipping.")
        return False
    dirty = False
    location_found = False
    network_found = False
    provision_found = False
    for part in issue.fields.description.content:
        if part.type == "paragraph" and part.content[0].type == "text":
            text = part.content[0].text
            match SomePrefix(text):
                case "Location:":
                    location_found = True
                    value = text[len("Location:"):].strip()
                    if value != f"TEL-L{dut.lab_room}-F{dut.frame}-S{dut.shief}-P{dut.partition}":
                        part.content[0].text = f"Location: TEL-L{dut.lab_room}-F{dut.frame}-S{dut.shief}-P{dut.partition}"
                        dirty = True
                case "Network status:":
                    network_found = True
                    value = text[len("Network status:"):].strip()
                    if value != network_status:
                        part.content[0].text = f"Network status: {network_status}"
                        dirty = True
                case "Provision Type:":
                    provision_found = True
                    value = text[len("Provision Type:"):].strip()
                    if value != dut.provision_method:
                        part.content[0].text = f"Provision Type: {dut.provision_method}"
    if not location_found:
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} is missing location.")
    if not network_found:
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} is missing network status.")
    if not provision_found:
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} is missing provision type.")
    if dirty:
        issue.update(description=adf_dump(issue.fields.description))
    if issue.fields.status.name != status:
        transitions = jira.transitions(issue)
        for transition in transitions:
            if transition["name"] == status:
                jira.transition_issue(issue, transition["id"])
                dirty = True
    if 'backlog' not in issue.fields.labels:
        issue.fields.labels.append('backlog')
        issue.update(fields={"labels": issue.fields.labels})
        dirty = True
    if dirty:
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} updated.")
    else:
        print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} exists.")
    return True


def create_issue(cid, dut):
    network_status = "connected" if dut.blocker.lower() == "connected" else "disconnected"
    status = "To Do: Cert Lab"
    desc = {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "C3 Link: "
                    },
                    {
                        "type": "text",
                        "text": f"https://certification.canonical.com/hardware/{cid}/",
                        "marks": [
                            {
                                "type": "link",
                                "attrs": {
                                    "href": f"https://certification.canonical.com/hardware/{cid}/"
                                }
                            }
                        ]
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "Frame:"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": f"Location: TEL-L{dut.lab_room}-F{dut.frame}-S{dut.shief}-P{dut.partition}"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": f"Network status: {network_status}"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": f"Provision Type: {dut.provision_method}"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "Image: N/A"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "Manifest:"
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "=========================================================================="
                    }
                ]
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "What to do: "
                    },
                    {
                        "type": "text",
                        "text": "Cert Lab Machine Racking Instruction",
                        "marks": [
                            {
                                "type": "link",
                                "attrs": {
                                    "href": "https://docs.google.com/document/d/1TDDaRN0q0qfa-a9MCwVBYAfn7bz-0bhKqR89QTJwIQg/edit?tab=t.0"
                                }
                            }
                        ]
                    }
                ]
            }
        ]
    }
    issue_dict = {
        "project": {
            "key": "TELOPS"
        },
        "summary": f"[Backlog] {cid}",
        "description": desc,
        "labels": ["backlog"],
        "issuetype": {
            "name": "General Task"
        }
    }
    issue = jira.create_issue(fields=issue_dict)
    transitions = jira.transitions(issue)
    for transition in transitions:
        if transition["name"] == status:
            jira.transition_issue(issue, transition["id"])
    print(f"https://warthogs.atlassian.net/browse/{issue.key} {issue.fields.summary} just created.")


if __name__ == "__main__":
    for cid in reversed(sorted(cids)):
        print(f"Checking {cid} ...")
        dut = cids[cid]
        jql = f'project = TELOPS AND summary ~ {cid}'
        dirty = False
        issues = jira.search_issues(jql)
        for issue in issues:
            if update_issue(cid, dut):
                dirty = True
        if not dirty:
            create_issue(cid, dut)
