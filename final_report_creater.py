import os, sys
import json
import datetime
import smtplib

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

html ="<html>\
<head><title>Monkey Android Test Report</title></head>\
<body>\
    <table border=1>\
        <th bgcolor=\"#FFFF00\" colspan=9>Monkey Android Test Report</th>\
        <tr>\
            <th bgcolor=\"#FFFF00\">Version</th>\
            <th bgcolor=\"#FFFF99\" colspan=8>{}</th>\
        <tr>\
        <th bgcolor=\"#FFFF00\" colspan=9>Monkey Test Parameters</th>\
        <tr>\
            <th bgcolor=\"#FFFF00\">Event delay (ms)</th>\
            <th bgcolor=\"#FFFF99\" colspan=8>200</th>\
        <tr>\
            <th bgcolor=\"#FFFF00\">Event counts</th>\
            <th bgcolor=\"#FFFF99\" colspan=8>500000</th>\
        <tr>\
            <th bgcolor=\"#FFFF00\">Others</th>\
            <th bgcolor=\"#FFFF99\" colspan=8></th>\
        <tr>\
            <th bgcolor=\"#FFFF00\" colspan=9>Test Result</th>\
        <tr>\
            <th bgcolor=\"#FFFF00\">Device</th>\
            <th bgcolor=\"#FFFF00\">Accumulative<br>event counts</th>\
            <th bgcolor=\"#FFFF00\">Total Dropped<br>Event</th>\
            <th bgcolor=\"#FFFF00\">Event drop<br>rate(%)</th>\
            <th bgcolor=\"#FFFF00\">Event Count Based<br>MTTF (hrs)</th>\
            <th bgcolor=\"#FFFF00\">Start-Time</th>\
            <th bgcolor=\"#FFFF00\">End-Time</th>\
            <th bgcolor=\"#FFFF00\">Earth-Time</th>\
            <th bgcolor=\"#FFFF00\">Result</th>\
"

result ="       <tr>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\">{}</th>\
            <th bgcolor=\"#FFFF99\" align=left>{}</th>"

report_html = open('index.html', 'w')


folder = datetime.datetime.now().strftime("%Y%m%d")
path = os.path.join("//MINSMCHIEN-3020/report/json", folder)


list_file=os.listdir(path)
count = 0
total_mttf = 0
first=False
for file in list_file:
    with open(os.path.join(path,file)) as json_file:
        data=json.load(json_file)
        if not first:
            first=True
            report_html.write(html.format(data['VER']))
        count += 1
        total_mttf += float(data['MTTF'])
        this_result = result.format(data['SN'], data['EVENT_COUNT'], data['DROP_COUNT'], data['DROP_RATE'], data['MTTF'], data['START_TIME'], data['STOP_TIME'], data['TOTAL_TIME'], data['RESULT'])
        report_html.write(this_result)

html_end ="       <tr>\
            <th bgcolor=\"#00FFFF\">AVERAGE</th>\
            <th bgcolor=\"#00FFFF\" colspan=3></th>\
            <th bgcolor=\"#00FFFF\">{}</th>\
            <th bgcolor=\"#00FFFF\" colspan=4></th>\
        <tr>\
    </table>\
</body>\
</html>".format(total_mttf/count)

report_html.write(html_end)
report_html.close()

# me == my email address
# you == recipient's email address
me = "FIH-SW2-AutoMonkeyReport@fih-foxconn.com"
#you = ["minsmchien@fih-foxconn.com", "YiChengChen@fih-foxconn.com", "LunYiKuo@fih-foxconn.com", "StanleyCheng@fih-foxconn.com", "ChungweiCheng@fih-foxconn.com"]
you = ["minsmchien@fih-foxconn.com", "AllenYPLin@fih-foxconn.com"]

# Create message container - the correct MIME type is multipart/alternative.
msg = MIMEMultipart('alternative')
msg['Subject'] = "Auto-monkey Report Test"
msg['From'] = me
msg['To'] = ','.join(you)

# Create the body of the message (a plain-text and an HTML version).
text = "Log Path:"
report=open('index.html', 'r').read()

# Record the MIME types of both parts - text/plain and text/html.
part1 = MIMEText(text, 'plain')
part2 = MIMEText(report, 'html')

# Attach parts into message container.
# According to RFC 2046, the last part of a multipart message, in this case
# the HTML message, is best and preferred.
msg.attach(part1)
msg.attach(part2)

# Send the message via local SMTP server.
s = smtplib.SMTP('mailgw.fihtdc.com')
# sendmail function takes 3 arguments: sender's address, recipient's address
# and message to send - here it is sent as one string.
s.sendmail(me, you, msg.as_string())
s.quit()


