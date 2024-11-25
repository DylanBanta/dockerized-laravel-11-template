### **How It Works**

1. **Create Environment Files**:
   - Copy `config/example.env` to a new file (e.g., `config/testing.env`) and edit the variables.

2. **Run `setup.sh`**:
   - Pass the `.env` file as an argument:
     ```bash
     ./setup.sh config/testing.env
     ```

3. **Generated Output**:
   - `setup.sh` replaces all `{PROJECT_NAME}` placeholders dynamically.
   - Example for `PROJECT_NAME=testing`:
     - `APP_SERVICE_NAME` becomes `app-testing`.
     - `MYSQL_DATABASE` becomes `testing_db`.

---

### **Test Example**
**Input**: `config/testing.env`:
```env
# General Configurations
PROJECT_NAME=testing.example.com
APP_SERVICE_NAME=app-{PROJECT_NAME}

# Network
NETWORK_NAME={PROJECT_NAME}_network

# Nginx
NGINX_SERVICE_NAME=nginx-{PROJECT_NAME}
NGINX_PORT=4444

# Database Configuration
MYSQL_SERVICE_NAME=mysql-{PROJECT_NAME}
MYSQL_DATABASE={PROJECT_NAME}_db
MYSQL_USER={PROJECT_NAME}_user
MYSQL_PASSWORD=my_password
MYSQL_ROOT_PASSWORD=root_password
MYSQL_PORT=4445

# Dockerfile Configurations
PHP_VERSION=8.3-fpm
PHP_EXTENSIONS=pdo_mysql mbstring exif pcntl bcmath gd
```

**Command**:
```bash
./setup.sh config/testing.env
```

**Output Directory**:
```
testing.example.com/
├── Dockerfile
├── docker-compose.yml
├── app-volume-testing/
├── nginx-volume-testing/
│   └── default.conf
├── mysql-volume-testing/
```