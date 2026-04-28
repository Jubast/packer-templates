# Redis configuration file
# ref - https://raw.githubusercontent.com/redis/redis/7.4/redis.conf

# Disable default user password, restrict to PING only for healthchecks
user default reset on nopass +PING +SELECT

# Nextcloud user
user nextcloud on >${database_redis_nextcloud_password} ~* &* +@all

# OnlyOffice user
user onlyoffice on >${database_redis_onlyoffice_password} ~* &* +@all
