已看到你有 `ifcfg-ens3`、`ifcfg-ens3:1`、`ifcfg-ens3:2`。按你的需求，继续把 `5.188.33.14` 和 `5.188.33.9` 加上：

- 临时生效（立刻可用，重启会丢失）
```bash
ip addr add 5.188.33.14/32 dev ens3 label ens3:3
ip addr add 5.188.33.9/32  dev ens3 label ens3:4
ip addr show ens3
```

- 持久化（新增两个文件）
```bash
cat > /etc/sysconfig/network-scripts/ifcfg-ens3:3 <<'EOF'
DEVICE=ens3:3
BOOTPROTO=none
IPADDR=5.188.33.14
NETMASK=255.255.255.255
ONBOOT=yes
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-ens3:4 <<'EOF'
DEVICE=ens3:4
BOOTPROTO=none
IPADDR=5.188.33.9
NETMASK=255.255.255.255
ONBOOT=yes
EOF
```

- 让配置生效（可能短暂断开 SSH，谨慎执行）
```bash
systemctl restart NetworkManager || (ifdown ens3:3; ifup ens3:3; ifdown ens3:4; ifup ens3:4)
# 不确定时，先别重启网络，直接重启整机也行：reboot
```

- 验证
```bash
ip addr show ens3
ping -c 3 5.188.33.14
ping -c 3 5.188.33.9
```

注意：
- 不一定要把 `.14` 设为“主 IP”。只要接口绑定了 `.14`，外部访问指向 `.14` 就能到达；你可直接把域名 A 记录改成 `5.188.33.14`。
- 若必须把主 IP 从 `5.188.33.167` 改为 `5.188.33.14`，需要改 `ifcfg-ens3` 里的 `IPADDR`，操作会中断 SSH，最好走控制台执行。需要我给出安全切换主 IP 的步骤吗？

我使用的是临时的方案。持久化的配置文件已经创建，但还没有用命令执行。