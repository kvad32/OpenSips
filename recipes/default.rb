#
# Cookbook Name:: OpenSips
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'apt'
include_recipe 'users'

# Install Packages
%w{gcc bison flex make openssl libmysqlclient-dev 
  perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl 
  libfrontier-rpc-perl libterm-readline-gnu-perl 
  libberkeleydb-perl mysql-server libxml2 libxml2-dev libxmlrpc-core-c3-dev 
  libpcre3 libpcre3-dev subversion libncurses5-dev ngrep git ngrep }.each do |pkg|
    package "#{pkg}"
  end

# Add Daemon User
user 'opensips' do
  home "/home/opensips"
  action :create
end

# Install and compile OpenSips
git "/opt/opensips" do
  repository "https://github.com/OpenSIPS/opensips.git"
  revision "1.11"
end

bash 'enable_on_boot' do
  user "root"
  code <<-EOC
    update-rc.d opensips defaults 99
  EOC
  action :nothing
end

bash 'compile_and_install' do
  user 'root'
  code <<-EOC
  cd /opt/opensips
  make prefix=/ include_modules="db_mysql, dialplan, presence, presence_xml, \
              presence_mwi, presence_dialoginfo, pua, pua_bla, pua_mi, pua_usrloc, \
              pua_xmpp, pua_dialoginfo, mi_xmlrpc, xcap" modules
  make prefix=/ install
  EOC
  action :nothing
end

cookbook_file "/etc/init.d/opensips" do
  owner "root"
  group "root"
  mode 755
  source "opensips.init"
  notifies :run, "bash[enable_on_boot]", :immediately
end

cookbook_file "/etc/default/opensips" do
  owner "root"
  group "root"
  source "opensips.default"
end

# OpenSips ctrl files
template "/etc/opensips/opensipsctlrc" do
  owner "root"
  group "root"
  mode 0644
  source "opensipsctlrc.erb"
end
