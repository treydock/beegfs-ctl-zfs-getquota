#!/usr/bin/env python

import argparse
import csv
import grp
import json
import os
import prettytable
import pwd
import re
import sys

YAML_SUPPORT = True
try:
    import yaml
except ImportError, e:
    if str(e) != "No module named yaml":
        raise
    else:
        YAML_SUPPORT = False

if YAML_SUPPORT:
    SUPPORTED_FORMATS = ["csv", "json", "yaml"]
else:
    SUPPORTED_FORMATS = ["csv", "json"]

def parse(args, parser):
    if args.output == None:
        args.output = "/tmp/fhgfs_%sspace.%s" % (args.quotatype, args.format)
    print args

    entries = []
    mtime = int(os.stat(args.input).st_mtime)
    lines = []
    with open(args.input) as f:
        lines = f.readlines()
    for line in lines:
        m = re.search('^([0-9]+)\s+([0-9]+)$', line)
        if not m:
            continue
        _id = int(m.group(1))
        _space = int(m.group(2))
        e = None
        for entry in entries:
            if entry["id"] == _id:
                e = entry
        if e:
            cur = e["space"]
            e["space"] = int(cur) + _space
        else:
            try:
                if args.quotatype == "group":
                    group = grp.getgrgid(_id)
                    name = group.gr_name
                elif args.quotatype == "user":
                    user = pwd.getpwuid(_id)
                    name = user.pw_name
                else:
                    name = None
            except KeyError:
                continue

            e = {}
            e["name"] = name
            e["id"] = _id
            e["space"] = _space
            e["mtime"] = mtime
            entries.append(e)
    sorted_entries = sorted(entries, key=lambda k: k["id"])

    if args.format == "csv":
        with open(args.output, "w") as csvfile:
            csvwriter = csv.writer(csvfile, delimiter=",")
            for entry in sorted_entries:
                csvwriter.writerow([entry["id"], entry["name"], entry["space"], entry["mtime"]])
    elif args.format == "json":
        with open(args.output, "w") as jsonfile:
            json.dump(sorted_entries, jsonfile, sort_keys=True, indent=4)
    elif args.format == "yaml":
        with open(args.output, "w") as yamlfile:
            yaml.dump(sorted_entries, yamlfile, default_flow_style=False)


def sizeof_fmt(num, suffix="B"):
    for unit in ["", "K", "M", "G", "T", "P"]:
        if abs(num) < 1024.0:
            return "%3.2f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.2f%s%s" % (num, "Y", suffix)


def report(args, parser):
    table_headers = ["Name", "ID", "Space", "mtime"]

    filename, ext = os.path.splitext(os.path.basename(args.input))
    entries = None
    if ext == ".csv":
        entries = []
        with open(args.input) as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",")
            for row in csvreader:
                entry = {}
                entry["id"] = row[0]
                entry["name"] = row[1]
                entry["space"] = int(row[2])
                entry["mtime"] = row[3]
                entries.append(entry)
    elif ext == ".json":
        with open(args.input) as jsonfile:
            entries = json.load(jsonfile)
    elif ext == ".yaml":
        with open(args.input) as yamlfile:
            entries = yaml.load(yamlfile)
    else:
        print "Unknown file format: %s" % ext
        sys.exit(1)

    table = prettytable.PrettyTable(table_headers)
    table.hrules = prettytable.FRAME
    sorted_entries = sorted(entries, key=lambda k: k["space"])
    total_space = 0
    for entry in sorted_entries:
        total_space = total_space + entry["space"]
        space = sizeof_fmt(entry["space"])
        table.add_row([entry["name"], entry["id"], space, entry["mtime"]])
    table.add_row(["","","",""])
    table.add_row(["Total", "---", sizeof_fmt(total_space), "---"])
    print table

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='mode')
parser_parse = subparsers.add_parser('parse')
parser_report = subparsers.add_parser('report')

parser_parse.add_argument("-i", "--inputfile", help="Input file", dest="input", required=True)
parser_parse.add_argument("-t", "--quotatype", help="Type of quota to parse", choices=["user", "group"], dest="quotatype", default="user")
parser_parse.add_argument("-o", "--output", help="Where to output quota report", dest="output")
parser_parse.add_argument("-f", "--format", help="Output format", choices=SUPPORTED_FORMATS, dest="format", default="json")
parser_parse.set_defaults(func=parse)

parser_report.add_argument("-i", "--inputfile", help="Input file", dest="input", required=True)
parser_report.set_defaults(func=report)

args = parser.parse_args()
args.func(args, parser)

