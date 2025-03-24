include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-drcom-cpp-client
PKG_VERSION:=1.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI Plugin for drcom_client
  DEPENDS:=+luci +libopenssl
endef

TARGET_CXXFLAGS += -Wno-deprecated-declarations

define Package/$(PKG_NAME)/description
  LuCI interface for drcom_client configuration and management.
endef

define Build/Prepare
	$(CP) -r ./src $(PKG_BUILD_DIR)/
endef

define Build/Compile
    sed -i 's/\r//' ./files/etc/init.d/drcom_client
    $(TARGET_CXX) $(TARGET_CXXFLAGS) -std=c++11 \
        -I$(STAGING_DIR)/usr/include \
        -I$(STAGING_DIR)/usr/include/yaml-cpp \
        -o $(PKG_BUILD_DIR)/drcom_client \
        $(PKG_BUILD_DIR)/src/main.cpp \
        $(PKG_BUILD_DIR)/src/config.cpp \
        $(PKG_BUILD_DIR)/src/utils.cpp \
        $(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib \
        -lssl -lcrypto \
        -Wl,-Bstatic -lyaml-cpp -Wl,-Bdynamic \
        -lpthread
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/drcom
	$(CP) ./files/usr/lib/lua/luci/controller/drcom.lua $(1)/usr/lib/lua/luci/controller/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/config.htm $(1)/usr/lib/lua/luci/view/drcom/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/advance.htm $(1)/usr/lib/lua/luci/view/drcom/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/log.htm $(1)/usr/lib/lua/luci/view/drcom/

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/drcom_client $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/drcom
	$(CP) ./files/etc/drcom/config.yaml $(1)/etc/drcom/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/drcom_client $(1)/etc/init.d/
	chmod 755 $(1)/etc/init.d/drcom_client
endef

$(eval $(call BuildPackage,$(PKG_NAME)))