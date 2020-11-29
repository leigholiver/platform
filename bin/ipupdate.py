import requests, boto3

# keep the security group updated with my current IP address
SEC_GROUP_NAME = 'platform_sec'

MY_IP = "%s/32" % requests.get("https://checkip.amazonaws.com").text.strip()
PORTS = [22, 16443, 6443] # SSH, microk8s, k3s
tasks = { 'missing': [], 'revoke': [] }

ec2 = boto3.client('ec2')
response = ec2.describe_security_groups(GroupNames=[SEC_GROUP_NAME])
sec_group = response['SecurityGroups'][0]

# find any rules we need to add/revoke
seen_ports = []
for rule in sec_group['IpPermissions']:
    if rule['FromPort'] in PORTS:
        seen_ports.append(rule['FromPort'])
        rule_ips = [rng['CidrIp'] for rng in rule['IpRanges']]
        if MY_IP not in rule_ips:
            tasks['missing'].append(rule['FromPort'])
            if len(rule_ips) > 0:
                tasks['revoke'].append({'port': rule['FromPort'], 'ips': rule_ips})

# add any ports we havent seen
for port in PORTS:
    if port not in seen_ports:
        tasks['missing'].append(port)

# perform the tasks
if len(tasks['revoke']) > 0:
    print("Revoking %d rules" % len(tasks['revoke']))
    print(tasks['revoke'])
    ec2.revoke_security_group_ingress(
        GroupId=sec_group['GroupId'],
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort':   r['port'],
                'ToPort':     r['port'],
                'IpRanges':   [{'CidrIp': ip} for ip in r['ips']]
            }
            for r in tasks['revoke']
        ]
    )

if len(tasks['missing']) > 0:
    print("Adding %d rules" % len(tasks['missing']))
    print(tasks['missing'])
    ec2.authorize_security_group_ingress(
        GroupId=sec_group['GroupId'],
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort':   port,
                'ToPort':     port,
                'IpRanges': [
                    {'CidrIp': MY_IP}
                ]
            }
            for port in tasks['missing']
        ]
    )
