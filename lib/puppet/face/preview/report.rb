require 'puppet/face'

Puppet::Face.define(:preview, '0.0.1') do
  extend Puppet::Util::Colors
  action :report do
    summary "Generate an HTML report of the preview tool"
    arguments "env"

    description <<-'EOT'
      This face runs the puppet preview command and parses the output into a consumable report
    EOT
    notes <<-'NOTES'
     This tool must be run on a master with access to the code and a populated/imported puppetdb or yaml cache. 
    NOTES
    examples <<-'EOT'
      Compare host catalogs:

      $ puppet preview report <environment>
    EOT

    when_invoked do |node_name, options|
      Puppet[:clientyamldir] = Puppet[:yamldir]
      output = [ {'Name' => 'Environment'} ]
      if node_name == '*'
       Puppet::Node.indirection.terminus_class = :yaml
        unless nodes = Puppet::Node.indirection.search(node_name)
          raise "Nothing returned from yaml terminus (yamldir set?)"
        end
        output << nodes.map { |node| Hash[node.name => node.environment] }
        output.flatten
      else
        unless node = Puppet::Node.indirection.find(node_name,:terminus => 'yaml' )
          raise "Nothing returned from yaml terminus for (#{node_name})"
        end
        clientcert = node.parameters['clientcert']
        raise "Results returned (#{clientcert})" if clientcert != node_name
        output << Hash[ node.name => node.environment]
        output
      end
    end

    when_rendering :console do |output|
      puts output.inspect
    end
  end
end
