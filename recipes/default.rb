#
# Cookbook Name:: solr-tomcat
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

bash 'install logging into tomcat (log4j-1.2.16.jar)' do
  code   "cp #{node.solr.extracted}/example/lib/ext/log4j-1.2.16.jar #{node.tomcat.endorsed_dir}/log4j-1.2.16.jar"
  not_if "test `sha256sum #{node.tomcat.endorsed_dir}/log4j-1.2.16.jar | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/lib/ext/log4j-1.2.16.jar | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

bash 'install logging into tomcat (slf4j-api-1.6.6.jar)' do
  code   "cp #{node.solr.extracted}/example/lib/ext/slf4j-api-1.6.6.jar #{node.tomcat.endorsed_dir}/slf4j-api-1.6.6.jar"
  not_if "test `sha256sum #{node.tomcat.endorsed_dir}/slf4j-api-1.6.6.jar | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/lib/ext/slf4j-api-1.6.6.jar | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

bash 'install logging into tomcat (slf4j-log4j12-1.6.6.jar)' do
  code   "cp #{node.solr.extracted}/example/lib/ext/slf4j-log4j12-1.6.6.jar #{node.tomcat.endorsed_dir}/slf4j-log4j12-1.6.6.jar"
  not_if "test `sha256sum #{node.tomcat.endorsed_dir}/slf4j-log4j12-1.6.6.jar | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/lib/ext/slf4j-log4j12-1.6.6.jar | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

bash 'install logging into tomcat (jcl-over-slf4j-1.6.6.jar)' do
  code   "cp #{node.solr.extracted}/example/lib/ext/jcl-over-slf4j-1.6.6.jar #{node.tomcat.endorsed_dir}/jcl-over-slf4j-1.6.6.jar"
  not_if "test `sha256sum #{node.tomcat.endorsed_dir}/jcl-over-slf4j-1.6.6.jar | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/lib/ext/jcl-over-slf4j-1.6.6.jar | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

bash 'install logging into tomcat (jul-to-slf4j-1.6.6.jar)' do
  code   "cp #{node.solr.extracted}/example/lib/ext/jul-to-slf4j-1.6.6.jar #{node.tomcat.endorsed_dir}/jul-to-slf4j-1.6.6.jar"
  not_if "test `sha256sum #{node.tomcat.endorsed_dir}/jul-to-slf4j-1.6.6.jar | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/lib/ext/jul-to-slf4j-1.6.6.jar | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end

bash 'install logging into tomcat (log4j.properties)' do
  code   "cp #{node.solr.extracted}/example/resources/log4j.properties #{node.tomcat.base}/common/classes/log4j.properties"
  not_if "test `sha256sum #{node.tomcat.base}/common/classes/log4j.properties | cut -d ' ' -f 1` = `sha256sum cp #{node.solr.extracted}/example/resources/log4j.properties | cut -d ' ' -f 1`"
  notifies :restart, resources(:service => "tomcat")
end


directory node.solr.data do
  owner     node.tomcat.user
  group     node.tomcat.group
  recursive true
  mode      "750"
end

template "#{node.tomcat.context_dir}/solr.xml" do
  owner  node.tomcat.user
  source "solr.context.erb"
  notifies :restart, resources(:service => "tomcat")
end

remote_directory node.solr.home do
  source       "example-solr"
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

cookbook_file "#{node.solr.home}/collection1/conf/schema.xml" do
  backup true
  source "example-nutch/schema-solr4.xml"
  notifies     :restart, resources(:service => "tomcat"), :immediately
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

