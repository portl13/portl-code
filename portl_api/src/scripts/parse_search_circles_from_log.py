#!/usr/bin/env python

import argparse
import json
import re
import sys

if __name__ == '__main__':
    "2018-04-06 10:18:34,504 [DEBUG] from com.portl.api.services.AggregatorService in application-akka.actor.default-dispatcher-2 - (r=118.03398874989489, latLng=(40.703453,-120.853321), count=236, depth=4, result=success)"
    r  = r'^([^ ]+ [^ ]+) \[(\w+)\] [^(]+\(r=([^,]+), latLng=\(([^,]+),([^)]+)\), count=(\d+), depth=(\d+), result=(\w+)'
    date_format = '%Y-%m-%d %H:%M:%S,%f'  # note this wants microseconds, so append 0s to input

    parser = argparse.ArgumentParser(
        description='Parses an application log file and produces JSON with a list '
                    'of circles suitable for rendering with Leaflet.js.')
    parser.add_argument('log_file', type=file)
    args = parser.parse_args()

    circles = []
    for line in args.log_file:
        match = re.match(r, line)
        if match:
            data = {
                # 'time': datetime.datetime.strptime('%s000' % match.group(1), date_format),
                'time': match.group(1),
                # level
                'radius': float(match.group(3)),
                'lat': float(match.group(4)),
                'lng': float(match.group(5)),
                'count': int(match.group(6)),
                'depth': int(match.group(7)),
                'result': match.group(8),
            }
            circles.append(data)
    json.dump(circles, sys.stdout)
    args.log_file.close()
