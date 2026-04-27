# Redis configuration file
# ref - https://raw.githubusercontent.com/redis/redis/7.4/redis.conf

# Disable default user password, restrict to PING only for healthchecks
user default reset on nopass +PING

# Nextcloud user
user nextcloud on >${database_redis_nextcloud_password} ~* &* +@read +@write +DEL +EXPIRE +TTL +SELECT

# OnlyOffice user
user onlyoffice on >${database_redis_onlyoffice_password} ~* &* +@read +@write +DEL +EXPIRE +TTL +SELECT
