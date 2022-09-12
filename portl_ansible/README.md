Portl Ansible Site
==========================
Manages Portl Web Service


License and Authors
-------------------
Authors: Francisco Gray, <fgray@concentricsky.com>


Notes
--------------------
*Portl Mongo Cluster*
- Staging and Production have deviated slightly, and so ansible should not be run against production until https://jira.concentricsky.com/browse/POR-1265 is completed
- Currently ansible does not run due to `mongodb_cluster_key` being undefined

New Cluster Setup START
----------------------
```javascript
    use admin
    db.createUser( { user: "cskyadmin", pwd: "{{ password - See TPM }}", roles: [ { role: "userAdminAnyDatabase", db: "admin" }, { role: "clusterManager", db:"admin"  }, { role : "dbAdminAnyDatabase", db : "admin" } ] })
    db.createUser( { user: "mongo_cloud", pwd: "{{ password }}", roles: [ { role : "clusterMonitor", db : "admin" }, { role : "readAnyDatabase", db : "admin" }, { role : "dbAdminAnyDatabase", db : "admin" } ] })
    db.createUser( { user: "backup", pwd: "{{ password - See TPM }}", roles: [ { role : "backup", db : "admin" }, { role : "readAnyDatabase", db : "admin" } ] })
    rs.initiate()
    rs.add("mongo2.review.portl.com")
    rs.add("mongo3.review.portl.com")
    use portl
    db.createUser( { user: "portl", pwd: "{{ password - See TPM }}", roles: [ "dbOwner" ]})
```

Backup Process
-----------------------
```bash
    mongodump --host mongo1.review.portl.com --port 27017 --ssl --sslAllowInvalidCertificates --username "backup" --password "{{ password }}" --authenticationDatabase "admin" --out ./20170320-staging --oplog 
```
```javascript
    db.grantRolesToUser("cskyadmin", [ { role : "root", db : "admin" }, ])
```

Create ReadOnly User
--------------------
```javascript

use {{ database_name }}
db.createUser({
    "user": "{{ username }}",
    "pwd": "{{ password }}",
    "roles": ["read"]
})

db.createUser( { user: "cskyadmin", pwd: "{{ password - See TPM }}", roles: [ { role: "userAdminAnyDatabase", db: "admin" }, { role: "clusterManager", db:"admin"  }, { role : "dbAdminAnyDatabase", db : "admin" } ] })
```
