#
# Cookbook Name:: solr
# Recipe:: default
#
# Copyright 2010, Jiva Technology Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "tomcat"

remote_file node.solr.download do
  source   node.solr.link
  checksum node.solr.checksum
  mode     0644
  action :create_if_missing
end

bash 'unpack solr' do
  code   "tar xzf #{node.solr.download} -C #{node.solr.directory}"
  not_if "test -d #{node.solr.extracted}"
end

bash 'install solr into tomcat' do
  code   "cp #{node.solr.war} #{node.tomcat.home}/webapps/solr.war"
  not_if "test `sha256sum #{node.tomcat.home}/webapps/solr.war | cut -d ' ' -f 1` = `sha256sum #{node.solr.war} | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

directory node.solr.data do
  owner     node.tomcat.user
  group     node.tomcat.group
  recursive true
  mode      "750"
end

template "#{node.tomcat.home}/contexts/solr.xml" do
  owner  node.tomcat.user
  source "solr.context.erb"
  notifies :restart, resources(:service => "tomcat")
end

remote_directory node.solr.config do
  source       "sunspot-1.2.1"
  owner        node.tomcat.user
  group        node.tomcat.group
  files_owner  node.tomcat.user
  files_group  node.tomcat.group
  files_backup 0
  files_mode   "644"
  purge        true

  notifies     :restart, resources(:service => "tomcat"), :immediately
  not_if       { File.exists? node.solr.config }
end


if node.solr.custom_lib

  bash "Copy custom lib to solr" do
    code <<-EOH
      rm -rf #{node.solr.lib}
      cp -r #{node.solr.custom_lib} #{node.solr.lib}
      chown -R #{node.tomcat.user}:#{node.tomcat.group} #{node.solr.lib}
      find #{node.solr.lib} -type f -exec chmod 640 \\;
      find #{node.solr.lib} -type d -exec chmod 750 \\;
    EOH
    notifies     :restart, resources(:service => "tomcat"), :immediately
    # Only copy the lib if it exists, and it is different from what is already there
    only_if <<-EOH
      test -e #{node.solr.custom_lib} &&
      ( diff -r #{node.solr.custom_lib} #{node.solr.lib}; test $? != 0 )
    EOH
  end

end

if node.solr.custom_config

  bash "Copy custom config to solr" do
    code <<-EOH
      rm -rf #{node.solr.config}
      cp -r #{node.solr.custom_config} #{node.solr.config}
      chown -R #{node.tomcat.user}:#{node.tomcat.group} #{node.solr.config}
      find #{node.solr.config} -type f -exec chmod 640 \\;
      find #{node.solr.config} -type d -exec chmod 750 \\;
    EOH
    notifies     :restart, resources(:service => "tomcat"), :immediately
    # Only copy the config if it exists, and it is different from what is already there
    only_if <<-EOH
      test -e #{node.solr.custom_config}/solrconfig.xml &&
      ( diff -r #{node.solr.custom_config} #{node.solr.config}; test $? != 0 )
    EOH
  end

end

remote_directory "/etc/solr/conf" do
  source       "sunspot-1.2.1"
  owner        node.tomcat.user
  group        node.tomcat.group
  files_owner  node.tomcat.user
  files_group  node.tomcat.group
  files_backup 0
  files_mode   "644"
  purge        true
  notifies     :restart, resources(:service => "tomcat")
  not_if       "test -e #{node.solr.custom_config}/solrconfig.xml"
end



