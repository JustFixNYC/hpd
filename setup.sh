#!/bin/bash

set -e

# create the database if needed
# createdb hpd

HPD_DATABASE=$(node -e "var c = require('./config.js'); console.log(c.pg.database)")
HPD_REGISTRATIONS_FILE=$(node -e "var c = require('./config.js'); console.log(c.data.registrations)")
HPD_CONTACTS_FILE=$(node -e "var c = require('./config.js'); console.log(c.data.contacts)")
BBL_LAT_LNG=$(node -e "var c = require('./config.js'); console.log(c.data.bbls)")

mkdir -p tmp

printf "Cleaning the data\n"
cat ${HPD_REGISTRATIONS_FILE} | python data_cleanup.py 16 1> tmp/registrations.txt 2> tmp/registrations_errors.txt
cat ${HPD_CONTACTS_FILE} | python data_cleanup.py 15 1> tmp/contacts.txt 2> tmp/contacts_errors.txt

printf "Removed "$(cat tmp/registrations_errors.txt | wc -l)" bad lines from the registrations data\n"
printf "Removed "$(cat tmp/contacts_errors.txt | wc -l)" bad lines from the contacts data\n"

HPD_REGISTRATIONS_FILE=$(pwd)/tmp/registrations.txt
HPD_CONTACTS_FILE=$(pwd)/tmp/contacts.txt

printf 'create table and COPY data\n'
psql -d ${HPD_DATABASE} -f 'sql/schema.sql'

printf 'Inserting data\n'
psql -d ${HPD_DATABASE} -c "COPY hpd.registrations FROM '"${HPD_REGISTRATIONS_FILE}"' (DELIMITER '|', FORMAT CSV, HEADER TRUE);"
psql -d ${HPD_DATABASE} -c "COPY hpd.contacts FROM '"${HPD_CONTACTS_FILE}"' (DELIMITER '|', FORMAT CSV, HEADER TRUE);"
psql -d ${HPD_DATABASE} -c "COPY hpd.bbl_lookup FROM '"${BBL_LAT_LNG}"' (FORMAT CSV,  HEADER TRUE);"

printf 'cleanup contact addresses\n'
psql -d ${HPD_DATABASE} -f 'sql/address_cleanup.sql'

printf 'cleanup registration addresses\n'
psql -d ${HPD_DATABASE} -f 'sql/registrations_clean_up.sql'

printf 'Add function anyarray_uniq()\n'
psql -d ${HPD_DATABASE} -f 'sql/anyarray_uniq.sql'

printf 'Add function anyarray_remove_null\n'
psql -d ${HPD_DATABASE} -f 'sql/anyarray_remove_null.sql'

printf 'Add aggregate functions first() and last()\n'
psql -d ${HPD_DATABASE} -f 'sql/first_last.sql'

printf 'Creating corporate_owners table\n'
psql -d ${HPD_DATABASE} -f 'sql/corporate_owners.sql'

# printf 'Geocodes corporate_owners\n'
# psql -d ${HPD_DATABASE} -f 'sql/google_geocode.sql'

printf 'Geocodes registrations via pluto\n'
psql -d ${HPD_DATABASE} -f 'sql/registrations_geocode.sql'

printf 'Creating table registrations_grouped_by_bbl\n'
psql -d ${HPD_DATABASE} -f 'sql/registrations_grouped_by_bbl.sql'

printf 'Indexing tables\n'
psql -d ${HPD_DATABASE} -f 'sql/index.sql'

printf 'Installing NPM modules\n'
npm install

printf 'Setting db permissions\n'
DB_USER=$(node -e "var c = require('./config.js'); console.log(c.pg.user)")
psql -d ${HPD_DATABASE} -c "GRANT USAGE ON SCHEMA hpd TO ${DB_USER}"
psql -d ${HPD_DATABASE} -c "GRANT SELECT ON ALL TABLES IN SCHEMA hpd TO ${DB_USER}"

printf 'Creating top500.txt file\n'
mkdir -p html/data
node get_corporate_owners_json.js 


# if [ ! -f registrations.zip ]; then
# 	printf 'Downloading data'
# 	wget -O registrations.zip http://www1.nyc.gov/assets/hpd/downloads/misc/Registrations20151201.zip
# fi
# if [ ! -f Registration20151130.txt ]; then
# 	unzip registrations.zip
#fi
