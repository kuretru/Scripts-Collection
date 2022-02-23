#!/bin/sh

DATA=$(cat <<- EOF
{
	"workNo": "学号",
	"name": "姓名  ",
	"sex": "1->性别",
	"campus": "2",
	"company": "计算机科学与技术学院、软件学院",
	"currentLocation": "浙江省杭州市西湖区",
	"whetherLeave": "2",
	"leaveReson": null,
	"leaveReasonInfo": null,
	"whetherInSchool": "1",
	"grade": "2020->年级",
	"mobile": "电话",
	"emLinkPerson": "紧急联系人",
	"emLinkMobile": "紧急联系人电话",
	"studentType": "2",
	"locationPandemic": "4",
	"meetRiskTime": null,
	"mentalStatus": "1",
	"temperatureOne": "36.0℃",
	"temperatureTwo": "36.0℃",
	"whetherSymptom": "2",
	"whetherMeetRisk": "2",
	"healthCode": "3",
	"whetherVaccine": "2",
	"whetherAllVaccine": "2",
	"agreement": true,
	"type": 1,
	"companyId": "21190"
}
EOF
)

curl \
    -H "Host: mryb.zjut.edu.cn" \
    -H "Accept: application/json, text/plain, */*" \
    -H "Accept-Language: zh-CN,zh-Hans;q=0.9" \
    -H "Content-Type: application/json;charset=utf-8" \
    -H "Origin: http://mryb.zjut.edu.cn" \
    -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/19D52 AliApp(DingTalk/6.3.30) com.laiwang.DingTalk/23075948 Channel/201200 language/zh-Hans-CN UT4Aplus/0.0.6 WK" \
    -H "DingTalk-Flag: 1" \
    -H "Referer: http://mryb.zjut.edu.cn/" \
    --data-binary "$DATA" \
    --compressed "http://mryb.zjut.edu.cn/htk/baseInfo/save"
