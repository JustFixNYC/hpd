var config = {};

config.pg = {};
config.data = {};

config.pg.user = 'your-pg-user-name';
config.pg.password = 'your-pg-password';
config.pg.database = 'hpd';

config.data.registrations = 'path/to/registrations.txt';
config.data.contacts = 'path/to/contacts.txt';

module.exports = config;
