### Simple Docker container to run a Magento 2 local instance cloning a Magento Cloud project branch

NOTE: to install Magento 2 following this guide you need Magento 2 access keys that can be retrived at the following URL https://marketplace.magento.com/customer/accessKeys and a token that can be generated at the following URL https://accounts.magento.cloud .
Container runs on php 7.4 therefore you will be able to install Magento versions 2.4 and above as for the following doc https://devdocs.magento.com/cloud/project/services.html#service-versions. Checkout the branch 2.4.0-2.4.3-p2 for versions benween 2.4.0 and 2.4.3-p2 that uses Composer version 1.


#### Create Docker image

```
docker build --no-cache --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" -t magento2 .
```

#### Create Docker network if it doesn't exist

```
docker network create commerce-cluster
```

#### Start Docker container

```
docker run --network commerce-cluster --name  magento-container -it -p 80:80 -p 443:443 magento2
```

### Inside the Docker container ..

#### become user ubuntu and login to Magento Cloud with a token created at https://accounts.magento.cloud

```
su - ubuntu
magento-cloud auth:api-token-login
magento-cloud ssh-cert:load
```

#### clone your magento.cloud project , to which you should have access logging in https://accounts.magento.cloud/user , into a dir called magento2

```
git clone --branch staging <magento_cloud_project_id>@git.us-4.magento.cloud:<magento_cloud_project_id>.git magento2
```

#### run composer to install Magento 2 dependencies

```
cd magento2
composer install
```

#### set right direcrory permissions

```
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
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

### on your host machine (not the Docker container) open a new terminal

#### pull Elasticsearch image that is required by Magento2 ver >=  2.4
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.9.0

#### run Elasticsearch container
docker run --network commerce-cluster --name elasticsearch-container -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.9.0


### Inside the Docker container ..

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
 --admin-email=narbone@whatever.com \
 --admin-user=admin \
 --admin-password=magento2 \
 --language=en_US \
 --currency=USD \
 --timezone=America/Chicago \
 --use-rewrites=1 \
 --elasticsearch-host=elasticsearch-container
```

#### set https front end and front end admin

```
bin/magento module:disable Magento_TwoFactorAuth
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

### on your host machine (not the Docker container) add 'magento2.local' to /etc/hosts

```
127.0.0.1 localhost magento2.local
```

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
