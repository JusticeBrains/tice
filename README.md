# PostgreSQL 16 Quick Setup & Remote Access Guide

## Overview

This README provides step-by-step instructions to install, configure, and enable remote access to PostgreSQL 16 on a Linux server. The setup includes database creation, user management, and firewall configuration for production environments.

---

## Prerequisites

- Ubuntu 22.04 LTS or equivalent Linux distribution
- Root or sudo access
- PostgreSQL 16 pre-installed (see installation if needed)
- Network access to the server

---

## Installation Steps

### 1. Verify PostgreSQL Version

Check that PostgreSQL 16 is installed and running:

```bash
sudo -u postgres psql --version
```

Expected output:
```
psql (PostgreSQL) 16.x
```

Verify the service is running:

```bash
sudo systemctl status postgresql
```

---

## PostgreSQL Configuration

### 2. Enable Remote Access

Edit the PostgreSQL configuration file to allow connections from any IP address:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Find and modify the following line (usually around line 60):

```ini
# Change from:
# listen_addresses = 'localhost'

# To:
listen_addresses = '*'
```

Save and exit (Ctrl+X, then Y, then Enter in nano).

---

### 3. Configure Host-Based Authentication (pg_hba.conf)

Edit the authentication configuration file:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Locate the IPv4 section and add/modify the following line to allow remote connections:

```
# TYPE  DATABASE  USER  ADDRESS      METHOD
host    all       all   0.0.0.0/0    scram-sha-256
```

**Note:** This configuration allows connections from any IP address. For production environments, replace `0.0.0.0/0` with your specific network range (e.g., `192.168.1.0/24`).

Save and exit the file.

---

### 4. Restart PostgreSQL Service

Apply the configuration changes by restarting PostgreSQL:

```bash
sudo systemctl restart postgresql
```

Or alternatively:

```bash
sudo service postgresql restart
```

Verify the service restarted successfully:

```bash
sudo systemctl status postgresql
```

---

## Database & User Setup

### 5. Create Database

Connect to PostgreSQL as the default postgres user:

```bash
sudo -u postgres psql
```

You should see the PostgreSQL prompt: `postgres=#`

Create a new database:

```sql
CREATE DATABASE myproject;
```

---

### 6. Create Database User

Create a new user with a secure password:

```sql
CREATE USER myprojectuser WITH PASSWORD 'password';
```

⚠️ **Security Warning:** Replace `'password'` with a strong, unique password. Use special characters, numbers, and mixed case.

---

### 7. Configure User Settings

Set the client encoding to UTF-8:

```sql
ALTER ROLE myprojectuser SET client_encoding TO 'utf8';
```

Set the default transaction isolation level:

```sql
ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';
```

Set the timezone to UTC:

```sql
ALTER ROLE myprojectuser SET timezone TO 'UTC';
```

---

### 8. Grant Database Privileges

Grant all privileges on the database to the new user:

```sql
GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;
```

Verify the setup:

```sql
\du
\l
```

Exit PostgreSQL:

```sql
\q
```

---

## Firewall Configuration

### 9. Allow PostgreSQL Traffic

Open the firewall to allow connections on port 5432 (PostgreSQL default port):

```bash
sudo ufw allow 5432/tcp
```

Reload the firewall rules:

```bash
sudo ufw reload
```

Verify the firewall rule was added:

```bash
sudo ufw status
```

You should see:

```
5432/tcp                   ALLOW       Anywhere
5432/tcp (v6)              ALLOW       Anywhere (v6)
```

---

## Testing Remote Access

### 10. Test Connection from Remote Machine

From a client machine with `psql` installed (or any PostgreSQL client):

```bash
psql -h <your_server_ip> -U myprojectuser -d myproject -p 5432
```

Replace `<your_server_ip>` with your server's IP address or hostname.

You should be prompted for the password you set during user creation.

Alternatively, use a connection string:

```bash
psql postgresql://myprojectuser:password@<your_server_ip>:5432/myproject
```

---

## Security Best Practices

### Important Security Considerations

1. **Strong Passwords:** Always use strong, unique passwords for database users.

   ```sql
   CREATE USER myprojectuser WITH PASSWORD 'Y0urStr0ng!P@ssw0rd';
   ```

2. **Restrict Access:** Instead of allowing `0.0.0.0/0`, restrict access to specific IP ranges:

   ```
   # In pg_hba.conf
   host    myproject  myprojectuser  192.168.1.0/24    scram-sha-256
   ```

3. **Use SSL/TLS:** For production environments, enable SSL encryption:

   ```ini
   # In postgresql.conf
   ssl = on
   ```

4. **Firewall Rules:** Limit port 5432 to specific trusted IPs instead of allowing all:

   ```bash
   sudo ufw allow from 192.168.1.100 to any port 5432 proto tcp
   ```

5. **Regular Backups:** Implement automated backup procedures.

6. **Monitor Logs:** Check PostgreSQL logs for unauthorized access attempts:

   ```bash
   sudo tail -f /var/log/postgresql/postgresql-16-main.log
   ```

---

## Common Commands Reference

### Database Operations

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# List all databases
\l

# List all users/roles
\du

# Connect to specific database
\c myproject

# Execute SQL file
psql -U myprojectuser -d myproject -f script.sql

# Backup database
pg_dump -U myprojectuser -d myproject > backup.sql

# Restore database
psql -U myprojectuser -d myproject < backup.sql
```

### User Management

```sql
-- Change user password
ALTER USER myprojectuser WITH PASSWORD 'new_password';

-- Grant additional privileges
GRANT CONNECT ON DATABASE myproject TO myprojectuser;

-- Drop user
DROP USER myprojectuser;

-- Drop database
DROP DATABASE myproject;
```

### Check Connection Status

```bash
# Show active connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Check if PostgreSQL is listening
sudo netstat -tunlp | grep postgres
```

---

## Troubleshooting

### PostgreSQL Won't Start

```bash
sudo systemctl start postgresql
sudo systemctl status postgresql
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

### Cannot Connect Remotely

1. Verify `listen_addresses = '*'` in `postgresql.conf`
2. Check `pg_hba.conf` allows your IP
3. Ensure firewall rule is active: `sudo ufw status`
4. Check if port 5432 is listening: `sudo netstat -tunlp | grep 5432`

### Authentication Failed

- Verify password is correct
- Check `pg_hba.conf` uses correct authentication method
- Ensure user has CONNECT privilege on database

### Performance Issues

Monitor connections and queries:

```bash
sudo -u postgres psql -d myproject -c "SELECT * FROM pg_stat_activity;"
```

Kill idle connections:

```sql
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE state = 'idle' AND query_start < now() - interval '30 minutes';
```

---

## Production Recommendations

For production deployments, consider:

1. **Connection Pooling:** Use PgBouncer to manage connection pools
2. **Replication:** Set up primary-replica replication for high availability
3. **Monitoring:** Implement Prometheus + Grafana for metrics
4. **Automated Backups:** Use pg_basebackup or WAL archiving
5. **SSL Certificates:** Use proper CA-signed certificates
6. **User Restrictions:** Create separate users with minimal required privileges
7. **Regular Updates:** Keep PostgreSQL and system packages updated

---

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/16/)
- [PostgreSQL Security Guidelines](https://www.postgresql.org/docs/16/sql-syntax.html)
- [pg_hba.conf Configuration](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html)

---

## Support & Issues

If you encounter issues:

1. Check PostgreSQL logs: `/var/log/postgresql/`
2. Review this README's troubleshooting section
3. Consult PostgreSQL official documentation
4. Check system resources (disk space, RAM, CPU)

---

**Last Updated:** December 2024  
**PostgreSQL Version:** 16.x  
**Ubuntu Version:** 22.04 LTS (or equivalent)