# OpenWRT Drcom客户端
## TODO
- [ ] 定时重启
- [ ] 优化界面

## 效果图
![d0f10eb81b6d6fe78ac6cffb63ca61c9](https://github.com/user-attachments/assets/22c9a127-f3a1-4147-95e8-ddfaddc09980)

## 编译
```
git clone https://github.com/azurstar/luci-app-drcom-cpp-client package/luci-app-drcom-cpp-client
cd package/luci-app-drcom-cpp-client
git submodule update --init --recursive --remote
cd ../..
make menuconfig
```
然后进入菜单选择 `luci-app-drcom-cpp-client`，最后执行
```
make V=s package/luci-app-drcom-cpp-client/compile -j8
```
完成！