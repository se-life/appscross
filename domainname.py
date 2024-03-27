pip install python-whois

import whois

def get_domain_info(domain):
    """
    获取域名的注册信息
    """
    domain_info = {}
    try:
        w = whois.whois(domain)
        domain_info['status'] = 'registered'
        domain_info['expiration_date'] = w.expiration_date
        domain_info['updated_date'] = w.updated_date
        domain_info['creation_date'] = w.creation_date
    except Exception as e:
        domain_info['status'] = 'unregistered'
    return domain_info

import datetime

def is_expired(domain_info):
    """
    判断域名是否过期
    """
    if domain_info['status'] == 'unregistered':
        return False
    elif type(domain_info['expiration_date']) is list:
        # 有些域名注册信息中的到期时间是一个列表，需要取第一个元素作为到期时间
        expiration_date = domain_info['expiration_date'][0]
    else:
        expiration_date = domain_info['expiration_date']
    days_left = (expiration_date - datetime.datetime.now()).days
    if days_left < 0:
        return True
    else:
        return False
