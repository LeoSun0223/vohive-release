# Quickstart

1. 安装最新版本：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash
```

```sh
wget -O - https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | sh
```

2. 查看服务状态：

```bash
systemctl status vohive
```

```sh
/etc/init.d/vohive status
```

3. 查看日志：

```bash
journalctl -u vohive -f
```

```sh
logread -f
```
