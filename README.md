# Basic Usage

This tool is built to consume the overview-json output of the [puppet preview
tool](https://github.com/puppetlabs/puppetlabs-catalog_preview)

You must first generate a report using preview.
```
sudo /opt/puppet/bin/puppet preview --preview-environment future_production
--migrate 3.8/4.0 --nodes nodes.txt --view overview-json >overview.json
```

Then clone this repo and install the markaby gem. This must be done on the same
system as you used to generate the preview report as we read the code of disk
as well as load the indivdiual nodes catalog_diff.json files for the report.


```shell
/opt/puppet/bin/gem install markaby
sudo ./preview_report.rb -f overview.json -w /vagrant/example.html
```

