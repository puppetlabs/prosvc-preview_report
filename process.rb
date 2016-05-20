#!/opt/puppet/bin/ruby
require 'markaby'
require 'json'

UNKNOWN_FILE_PATH = 'unknown location'

def load_json(filename)
  JSON.parse( IO.read(filename) )
end

overview = load_json('overview.json')
stats   = overview['stats']
preview = overview['preview']

mab = Markaby::Builder.new
mab.html do
  def make_error_readable(error)
    h5.entryTitle "Information about this issue"
    case error
    # MIGRATE4_REVIEW_IN_EXPRESSION
    when 'MIGRATE4_REVIEW_IN_EXPRESSION'
      tag! :body, :id => "overview_#{error}_#{rand()}" do
        <<-eos
        In Puppet 3, the #{tag! :code, 'in'} operator was not well specified and there were several undefined behaviors. This relates to, but is not limited to:
        eos
      end
      ul do
        li 'String / numeric automatic conversions.'
        li 'Applying regular expressions to non string values causing auto conversion.'
        li 'Confusion over comparisons between empty string/undef/nil (internal) values.'
        li 'In-operator not using case independent comparisons in Puppet 3.'
      end
      br
      body 'To fix, review the expectations against the Puppet language specification.'
      br
      body "For a detailed description of this issue, see "
      a 'PUP-4130', :href => 'https://tickets.puppetlabs.com/browse/PUP-4130'
    else
      tag! :body, :id => "overview_#{error}_#{rand()}" do
         a "No information defined for this error click here for more infromation", :href => "https://forge.puppet.com/puppetlabs/catalog_preview#%s" % error.downcase
      end
    end
  end

  def read_code_off_disk(header,manifest,line_number)
    hr
    line_number = (line_number.to_i + 1)
    # Read the file off disk to find the code question.
    file = File.readlines(manifest)
    #### Manifests Code Block
    tag! :code, :id => "manifest_#{header}_#{manifest}_#{line_number}_#{rand()}" do
      ((line_number - 1)..(line_number + 1)).each do |nu|
        div.entryContent do
          if nu == line_number - 1 
            "#{tag! :b, nu}:#{tag! :b, file[(nu - 1)]}"
           else
            "#{nu}:#{file[(nu - 1)]}"
           end
        end
      end
    end
    hr
  end

  def node_break_down(nodes)
    ul do
      # Only show 10 nodes
      h5 "#{nodes.length} nodes with this issue"
      nodes[0..10].each do |node|
          li do
            a node, :href => "ssh://root@#{node}"
          end
      end
    end
  end

  head { title "Diff Overview" }
  body do

    error_message = Hash.new
    # TOP TEN
    h1 "Top 10 nodes with issues"
    body "The following nodes had the most issues including missing or conflicting catalogs."
    br
    body "These nodes are likely the best for testing the breakdown issue list below."
    ul do
      overview['top_ten'].each do |node|
        preview_log = load_json("/var/opt/lib/pe-puppet/preview/#{node['name']}/preview_log.json")
        li do
          "#{tag! :b,node['issue_count']} issues on #{node['name']}"
        end
        ul do
          preview_log.each do |issue|
            li do
              # Work around the fact overview doesn't have human readable messages
              # we store them here and then use them in the breakdown below
              error_message[issue['issue_code']] = issue['message']
              a "#{issue['file']}:#{issue['line']}", :href => "#%s" % issue['file'].gsub(/[\/\.]/,'_')
            end
          end
        end
      end
    end
    total_failures = stats['failures']['total'] || 0

    # FAILURES
    unless total_failures == 0 
      h1 "Catalog Compliation Failures"
      div.failure_overview! {
        # 0 out X summary
        <<-eos
        #{tag! :strong, stats['node_count'] - total_failures} out of #{stats['node_count']} failed to compile their catalog.
        This is #{tag! :strong, stats['failures']['percent']}% failure rate across your infrastructure
        eos
      }
      # FILE WITH ISSUES 
      h1 "Files that caused the most failures"
      # Compliation Errors Breakdown
      ul do
        next unless preview['compilation_errors']
        preview['compilation_errors'].each do |error|
          ul do
            li "#{error['nodes'].length} nodes failed to compile: #{error['manifest']}"
            ul do
              div.entry do

                #### Error by line breakdown
                error['errors'].each do |e|
                  h4.entryTitle "#{e['message']} on line #{e['line']}"
                  # Read the file off disk to find the code question.
                  read_code_off_disk('failed',error['manifest'],e['line'])
                  #### Example nodes
                  node_break_down(nodes)
                end
              end
            end
          end
        end
      end
    end
    # CONFLICTS
    if stats['conflicting'] 
      total_conflicts = stats['conflicting']['total'] || 0
      h1 "Catalog Compliation Conflicts/Differences"
      div.conflict_overview! {
        # 0 out X summary
        <<-eos
        #{tag! :strong, stats['node_count'] - total_conflicts} out of #{stats['node_count']} have conflicts/differences in their catalog.
        This is #{tag! :strong, stats['conflicting']['percent']}% conflict rate across your infrastructure
        eos
      }
      preview['warning_count_by_issue_code'].each do |issue|
        ul do
          issue['manifests'].each do |manifest,lines|
            li do
              a manifest, :name => manifest.gsub(/[\/\.]/,'_')
            end
            ul do
              #### Error by line breakdown
              lines.uniq.each do |linepos|
                line_number = linepos.split(':')[0]
                # Use the preview message human readable and fallback to issue code when not present
                h4.entryTitle "Line #{line_number}: #{error_message[issue['issue_code']] || issue['issue_code']}"

                read_code_off_disk('warning',manifest,line_number)

                br
                # Show human reable error or link
                make_error_readable(issue['issue_code'])
              end
            end 
          end
        end
      end
      # CHANGES
      if overview['changes']
        h1 "Resources with changes or conflicts"
        overview['changes']['resource_type_changes'].each do |type,details|
          ul do
            # Type i.e. Class,File 
            h2 type
            hr
            def process_breakdown(header,type,detail)
              h3 "#{header.capitalize} #{type} resources"
              detail.each do |title,breakdown|
                ul do
                  li do
                    "#{tag! :b, type}[#{title}]"
                  end
                  breakdown.each do |path,nodes|
                  #### Example nodes
                  ul do
                    ul do
                      # Path for classes is unknown
                      unless path == UNKNOWN_FILE_PATH
                         file_path,line_number = path.split(':')
                         h5.entryTitle "#{header.capitalize} resource from line #{line_number}"
                         body path
                         div
                         read_code_off_disk(header,file_path,line_number)
                         br
                        end
                      end
                      # N number of example nodes
                      node_break_down(nodes)
                      br
                    end
                  end
                end
              end
            end
            if details['missing_resources']
              process_breakdown('missing',type,details['missing_resources'])
            end
            if details['conflicting_resources']
              process_breakdown('conflicting',type,details['conflicting_resources']) 
            end
          end
        end
      end
    end
  end
end

puts mab.to_s
