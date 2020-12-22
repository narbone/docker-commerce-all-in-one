### Simple Docker container to run a Magento 2 local instance cloning a Magento Cloud project branch

NOTE: before you start, be sure you remember the credentials to access the Magento Cloud - https://accounts.magento.cloud

#### Create Docker image

```
docker build --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" -t magento2.4 .
```

#### Start Docker container

```
docker run -it -p 80:80 -p 443:443 --add-host elasticsearch.magento.local:172.17.0.2 magento2.4
```

### Inside the Docker container ..

#### become user ubuntu

```
su - ubuntu
```

#### clone magento2.4 repo

```
git clone https://github.com/narbone/magento-commerce.git magento2
```

#### run composer to install Magento 2 dependencies

```
cd magento2
composer install
```

#### set right direcrory permissions

```
find var generated vendor pub/static pub/media app/etc -type f -exec chmod u+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod u+w {} +
chmod u+x bin/magento
```

#### become root and start the services

```
exit
```

```
service nginx start
service php7.4-fpm start
service mysql start
```

#### create magento2 Maria DB database and user

```
mysql -e "create database magento2; \
create user magento2 IDENTIFIED BY 'magento2'; \
GRANT ALL ON magento2.* TO magento2@localhost IDENTIFIED BY 'magento2'; \
flush privileges; \
"
```

#### install Magento as ubuntu user

```
su - ubuntu
cd magento2
```

```
bin/magento setup:install \
 --base-url=http://magento2.local \
 --db-host=localhost \
 --db-name=magento2 \
 --db-user=magento2 \
 --db-password=magento2 \
 --backend-frontname=admin \
 --admin-firstname=admin \
 --admin-lastname=admin \
 --admin-email=narbone@adobe.com \
 --admin-user=admin \
 --admin-password=magento2 \
 --language=en_US \
 --currency=USD \
 --timezone=America/Chicago \
 --use-rewrites=1 \
  --elasticsearch-host=172.17.0.2 \
 --elasticsearch-port=9200 \
 --elasticsearch-enable-auth=0
```

#### optionally, use https on front end

```
bin/magento setup:store-config:set --base-url-secure="https://magento2.local/"
bin/magento setup:store-config:set --use-secure 1
bin/magento config:set web/secure/use_in_adminhtml 1
```

#### run db module upgrades, compile DI, reindex and clean the cache

```
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento indexer:reindex
bin/magento cache:flush
```

#### on your host machine (not the Docker container) add 'magento2.local' to /etc/hosts

127.0.0.1 localhost **magento2.local**

### Web UI

url: http://magento2.local \
optional url: https://magento2.local \
admin url: http://magento2.local/admin \
login: admin \
password: magento2

#### To access to Maria DB as root, inside the container, type

```
mysql
```
