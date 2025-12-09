include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-drcom-cpp-client
PKG_VERSION:=v2.0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_SOURCE_SUBDIR := src

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	TITLE:=LuCI Plugin for drcom_client
	DEPENDS:=+luci +libopenssl +libstdcpp
endef

TARGET_CXXFLAGS += -Wno-deprecated-declarations

define Package/$(PKG_NAME)/description
	LuCI interface for drcom_client configuration and management.
endef

define Build/Prepare
	sed -i 's/\r//' ./files/etc/init.d/drcom_client
	$(CP) -r ./src $(PKG_BUILD_DIR)/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/drcom
	$(CP) ./files/usr/lib/lua/luci/controller/drcom.lua $(1)/usr/lib/lua/luci/controller/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/config.htm $(1)/usr/lib/lua/luci/view/drcom/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/advance.htm $(1)/usr/lib/lua/luci/view/drcom/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/log.htm $(1)/usr/lib/lua/luci/view/drcom/
	$(CP) ./files/usr/lib/lua/luci/view/drcom/status.htm $(1)/usr/lib/lua/luci/view/drcom/

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/drcom_client $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/drcom
	$(CP) ./files/etc/drcom/config.yaml $(1)/etc/drcom/
	$(CP) ./files/etc/drcom/keep_alive.sh $(1)/etc/drcom/
	chmod 755 $(1)/etc/drcom/keep_alive.sh

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/drcom_client $(1)/etc/init.d/
	chmod 755 $(1)/etc/init.d/drcom_client
endef

$(eval $(call BuildPackage,$(PKG_NAME)))