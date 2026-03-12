# MySQL 数据备份与恢复操作指南

## 概述
本文档记录了从远程 CentOS 服务器备份 Telegram 数据库到本地 Docker MySQL 容器的完整操作流程。

## 服务器环境信息
- **服务器**: CentOS
- **域名**: ********
- **数据库**: telegram
- **用户名**: telegram
- **密码**: 3rY3LstkiM6bsiBa

## 本地环境信息
- **系统**: Windows 11
- **MySQL**: Docker 容器 `sunphp-mysql`
- **项目路径**: `D:\me\epiboly\fuye\projects\webman`

---

## 一、服务器端操作

### 1. 连接数据库
```bash
mysql -u telegram -p3rY3LstkiM6bsiBa telegram
```

### 2. 检查日志文件
```bash
# 查看今天的日志文件
ls -la logs/$(date +%Y)/$(date +%m)/$(date +%d).log
```

### 3. 备份数据库
```bash
# 第一次尝试（遇到权限问题）
mysqldump -u telegram -p3rY3LstkiM6bsiBa telegram > telegram_backup.sql

# 成功备份（跳过表空间信息）
mysqldump -u telegram -p3rY3LstkiM6bsiBa telegram --single-transaction --no-tablespaces > telegram_backup.sql
```

### 4. 验证备份文件
```bash
# 查看文件列表
ls
ll

# 查看备份文件内容
head -20 telegram_backup.sql
```

### 5. 压缩并下载
```bash
# 压缩备份文件
gzip telegram_backup.sql

# 查看压缩后的文件
ls

# 下载到本地（使用 sz 命令）
sz telegram_backup.sql.gz
```

---

## 二、本地操作

### 1. 检查 Docker 容器
```bash
# 查看运行中的容器
docker ps
```

### 2. 连接本地 MySQL
```bash
# 进入 MySQL 容器
docker exec -it sunphp-mysql mysql -u root -p
```

### 3. 创建数据库和用户
在 MySQL 中执行：
```sql
-- 创建数据库
CREATE DATABASE telegram CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 创建用户
CREATE USER 'telegram'@'%' IDENTIFIED BY '3rY3LstkiM6bsiBa';

-- 授权
GRANT ALL PRIVILEGES ON telegram.* TO 'telegram'@'%';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 4. 导入数据（PowerShell 环境）

#### 方法1：直接导入（失败）
```powershell
# PowerShell 不支持 < 重定向
docker exec -i sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram < /temp/telegram_backup.sql
```

#### 方法2：复制文件到容器
```powershell
# 复制 SQL 文件到容器
docker cp .\temp\telegram_backup.sql sunphp-mysql:/tmp/telegram_backup.sql
```

#### 方法3：进入容器执行
```bash
# 进入容器
docker exec -it sunphp-mysql bash

# 在容器内导入数据
mysql -u telegram -p3rY3LstkiM6bsiBa telegram < /tmp/telegram_backup.sql
```

#### 方法4：使用 source 命令（成功）
```powershell
# 使用 source 命令导入
docker exec -i sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram -e "source /tmp/telegram_backup.sql"
```

### 5. 验证导入结果
```bash
# 查看表结构
docker exec -it sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram -e "SHOW TABLES;"
```

---

## 三、常见问题与解决方案

### 1. 权限问题
**问题**: `Access denied; you need (at least one of) the PROCESS privilege(s)`
**解决**: 使用 `--no-tablespaces` 参数跳过表空间信息

### 2. PowerShell 重定向问题
**问题**: PowerShell 不支持 `<` 重定向操作符
**解决**: 
- 使用 `docker cp` 复制文件到容器
- 使用 `source` 命令在容器内执行
- 使用 `Get-Content` 管道

### 3. 文件路径问题
**问题**: Windows 路径格式与 Linux 不同
**解决**: 使用相对路径 `.\temp\` 而不是 `/temp/`

---

## 四、验证命令

### 检查数据库连接
```bash
# 测试连接
docker exec -it sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram -e "SELECT COUNT(*) FROM tg_bots;"
```

### 查看机器人数据
```sql
SELECT 
    id,
    botname,
    nickname,
    CONCAT(LEFT(token, 10), '...') as token_preview,
    CASE WHEN status = 1 THEN '启用' ELSE '禁用' END as status,
    FROM_UNIXTIME(created_at) as created_time
FROM tg_bots;
```

---

## 五、项目配置

确保本地项目配置与服务器一致：

```php
// plugin/admin/config/database.php
return [
    'default' => 'mysql',
    'connections' => [
        'mysql' => [
            'driver'      => 'mysql',
            'host'        => 'localhost',
            'port'        => '3306',
            'database'    => 'telegram',
            'username'    => 'telegram',
            'password'    => '3rY3LstkiM6bsiBa',
            'charset'     => 'utf8mb4',
            'collation'   => 'utf8mb4_general_ci',
            'prefix'      => '',
            'strict'      => true,
            'engine'      => null,
        ],
    ],
];
```

---

## 六、操作记录

### 服务器端命令历史
```bash
276  mysql -u telegram -p3rY3LstkiM6bsiBa telegram
277  ls -la logs/$(date +%Y)/$(date +%m)/$(date +%d).log
278  mysqldump -u telegram -p3rY3LstkiM6bsiBa telegram > telegram_backup.sql
279  mysqldump -u telegram -p3rY3LstkiM6bsiBa telegram --single-transaction --no-tablespaces > telegram_backup.sql
280  ls
281  ll
282  head -20 telegram_backup.sql 
283  gzip telegram_backup.sql
284  ls
285  sz telegram_backup.sql.gz
```

### 本地命令历史
```bash
2  docker ps
3  docker ps
4  docker exec -it sunphp-mysql mysql -u root -p
5  docker exec -it sunphp-mysql mysql -u root -p
6  docker exec -i sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram < /temp/telegram_backup.sql
7  docker cp /temp/telegram_backup.sql sunphp-mysql:/tmp/telegram_backup.sql
8  docker exec -it sunphp-mysql bash
9  docker cp .\temp\telegram_backup.sql sunphp-mysql:/tmp/telegram_backup.sql
10  docker exec -i sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram -e "source /tmp/telegram_backup.sql"
11  docker exec -it sunphp-mysql mysql -u telegram -p3rY3LstkiM6bsiBa telegram -e "SHOW TABLES;"
```

---

## 七、总结

通过以上步骤，成功将远程服务器的 Telegram 数据库完整备份并恢复到本地 Docker MySQL 容器中，确保了开发环境与生产环境的数据一致性。

**关键成功因素**：
1. 使用 `--no-tablespaces` 参数解决权限问题
2. 使用 `docker cp` 和 `source` 命令解决 PowerShell 重定向问题
3. 确保数据库配置完全一致

**注意事项**：
- 定期备份生产数据
- 确保本地环境与生产环境配置一致
- 测试数据导入后的功能完整性

---

*文档生成时间: 2025年9月20日*
*操作环境: CentOS 服务器 + Windows 11 本地开发环境*
