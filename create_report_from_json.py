import os, sys
import json
import datetime
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Environment Variables
folder = datetime.datetime.now().strftime("%Y%m%d")
json_path = os.path.join("//MINSMCHIEN-3020/report/json", folder)
file_list = os.listdir(json_path)
data_list = []

# Get All JSON Data
for file in file_list:
    if file.endswith(".json"):
        with open(os.path.join(json_path, file)) as json_file:
            data = json.load(json_file)
            data_list.append(data)

# Create Summary Tabel
if 0 < len(data_list):
    report = open(os.path.join(json_path, 'index.html'), 'w')
    # summary table
    report.write('Hi All,<br>\n1. 500000 events, 200ms interval.<br>\n2. Blacklist: com.google.android.googlequicksearchbox<br><br>\n')
    report.write('<table border=\'2\' cellpadding=\'20\'>\n    <tr><th>Test Target</th><th>Test Result</th><th>Result Analysis</th>\n')
    for data in data_list:
        if 'PASS' == data['RESULT']:
            result = 'Finished'
        else:
            result = 'Fail'
        temp = "    <tr><td>{}<br>{}</td><td>1. Monkey {}<br>2. USB adb N/A<br>3. Touch Panel N/A</td><td>{}</td></tr>\n".format(data['VER'], data['SN'], result, data['RESULT'])
        report.write(temp)
    report.write("</table><br><br>\n\n")

    # Log Path
    log_path = "\\\\10.57.47.214\\AutoMK_MS3\\AutoMonkeyLog\\MS3\\Logs\\" + datetime.datetime.now().strftime("%Y%m%d")
    report.write("<b>Log path: <a href=\"{}\">{}</a></b><br><br>\n\n".format(log_path, log_path))

    # Monkey Result Table
    html ="<html>\n\
    <head><title>Monkey Android Test Report</title></head>\n\
    <body>\n\
        <table border=1>\n\
            <th bgcolor=\"#FFFF00\" colspan=9>Monkey Android Test Report</th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\">Version</th>\n\
                <th bgcolor=\"#FFFF99\" colspan=8>{}</th>\n\
            <tr>\n\
            <th bgcolor=\"#FFFF00\" colspan=9>Monkey Test Parameters</th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\">Event delay (ms)</th>\n\
                <th bgcolor=\"#FFFF99\" colspan=8>200</th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\">Event counts</th>\n\
                <th bgcolor=\"#FFFF99\" colspan=8>500000</th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\">Others</th>\n\
                <th bgcolor=\"#FFFF99\" colspan=8></th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\" colspan=9>Test Result</th>\n\
            <tr>\n\
                <th bgcolor=\"#FFFF00\">Device</th>\n\
                <th bgcolor=\"#FFFF00\">Accumulative<br>event counts</th>\n\
                <th bgcolor=\"#FFFF00\">Total Dropped<br>Event</th>\n\
                <th bgcolor=\"#FFFF00\">Event drop<br>rate(%)</th>\n\
                <th bgcolor=\"#FFFF00\">Event Count Based<br>MTTF (hrs)</th>\n\
                <th bgcolor=\"#FFFF00\">Start-Time</th>\n\
                <th bgcolor=\"#FFFF00\">End-Time</th>\n\
                <th bgcolor=\"#FFFF00\">Earth-Time<br>(minutes)</th>\n\
                <th bgcolor=\"#FFFF00\">Result</th>\n"
    report.write(html.format(data_list[0]['VER']))
    result_templete ="            <tr>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\">{}</th>\n\
                <th bgcolor=\"#FFFF99\" align=left>{}</th>\n"

    total_mttf = 0
    for data in data_list:
        total_mttf += float(data['MTTF'])
        this_result = result_templete.format(data['SN'], data['EVENT_COUNT'], data['DROP_COUNT'], data['DROP_RATE'], data['MTTF'], data['START_TIME'], data['STOP_TIME'], data['TOTAL_TIME'], data['RESULT'])
        report.write(this_result)

    html_end ="           <tr>\n\
                <th bgcolor=\"#00FFFF\">AVERAGE</th>\n\
                <th bgcolor=\"#00FFFF\" colspan=3></th>\n\
                <th bgcolor=\"#00FFFF\">{}</th>\n\
                <th bgcolor=\"#00FFFF\" colspan=4></th>\n\
        </table>\n\
    </body>\n</html>\n".format(total_mttf/len(data_list))
    report.write(html_end)
    report.close()

    # Send Mail to Mail List
    # me == my email address
    # you == recipient's email address
    me = "FIH-SW2-AutoMonkeyReport@fih-foxconn.com"
    #you = ["HankHuang@fih-foxconn.com", "StanleyCheng@fih-foxconn.com", "TerenceJCLin@fih-foxconn.com", "LouisLee@fih-foxconn.com", "AnnYCWang@fih-foxconn.com", "ChungweiCheng@fih-foxconn.com"]
    #cc = ["YiChengChen@fih-foxconn.com", "BillieLBShen@fih-foxconn.com", "LunYiKuo@fih-foxconn.com", "HylixRSLin@fih-foxconn.com", "MistyZheng@fih-foxconn.com", "YimoChang@fih-foxconn.com", "WSChien@fih-foxconn.com", "JohnYu@fih-foxconn.com", "ericyou@fih-foxconn.com"]
    you = ["YiChengChen@fih-foxconn.com", "LunYiKuo@fih-foxconn.com"]
    cc = ["StanleyCheng@fih-foxconn.com", "ChungweiCheng@fih-foxconn.com", "MinSMChien@fih-foxconn.com"]

    # Create message container - the correct MIME type is multipart/alternative.
    msg = MIMEMultipart('alternative')
    msg['Subject'] = "MS3 Monkey Test Report " + datetime.datetime.now().strftime("%Y%m%d")
    msg['From'] = me
    msg['To'] = ','.join(you)
    msg['CC'] = ','.join(cc)

    # Create the body of the message (a plain-text and an HTML version).
    text = "Log Path:"
    report=open(os.path.join(json_path, 'index.html'), 'r').read()

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
    you.extend(cc)
    s.sendmail(me, you, msg.as_string())
    s.quit()
else:
    # No JSON Files, Send Mail To ME
    print('No JSON Files Available')



