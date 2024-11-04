#!/bin/bash

cd /var/www/brat/brat-1.3p1 && /var/www/brat/brat-1.3p1/install.sh <<EOD
$BRAT_USERNAME 
$BRAT_PASSWORD 
$BRAT_EMAIL
EOD

chown -R www-data:www-data /bratdata

# patch the user config with more users
python /var/www/brat/brat-1.3p1/user_patch.py

echo "Install complete. You can log in as: $BRAT_USERNAME"

exit 0
