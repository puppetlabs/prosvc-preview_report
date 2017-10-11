#!/bin/bash

# Wrapper script for preview_report.rb that handles locating PE Ruby across
# different PE versions.

if [[ -x /opt/puppetlabs/puppet/bin/ruby ]]; then
  # PE 2015.x and newer
  PUPPET_RUBY=/opt/puppetlabs/puppet/bin/ruby
elif [[ -x /opt/puppet/bin/ruby ]]; then
  # PE 3.x
  PUPPET_RUBY=/opt/puppet/bin/ruby
else
  printf "The preview_report tool requires PE 3.x or newer to be installed.\n" 1>&2
  exit 1
fi

PREVIEW_REPORT="${BASH_SOURCE%/*}/preview_report.rb"

if [[ ! -f "${PREVIEW_REPORT}" ]]; then
  printf "Could not find %s.\n" "${PREVIEW_REPORT}" 1>&2
  exit 1
fi

"${PUPPET_RUBY}" -- "${PREVIEW_REPORT}" "$@"
