FROM ghost:5.62.0

# copy themes (casper) to container
COPY ghost/core/content/themes/casper /var/lib/ghost/current/content/themes/casper
COPY config.prod.json /var/lib/ghost/config.prod.json