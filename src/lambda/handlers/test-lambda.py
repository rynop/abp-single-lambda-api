from urllib.request import urlopen
import gzip
import shutil
import json
import sys
import datetime
import os
import mysql.connector

def main(event, context, **kwargs):
    print("hello world")
    for i in kwargs:
        print(i)
    for e in event:
        print(e)
    print(context)
