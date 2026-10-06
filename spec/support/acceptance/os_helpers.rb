# frozen_string_literal: true

module JavaAcceptanceHelpers::OsHelpers
  def os_facts
    JavaAcceptanceHelpers.cached_os_facts ||= JSON.parse(target_shell('facter --json os').stdout)['os']
  end

  def os_family
    os_facts['family']
  end

  def os_release_major
    os_facts.dig('release', 'major').to_s
  end

  def os_architecture
    os_facts['architecture']
  end

  def redhat?
    os_family == 'RedHat'
  end

  def debian?
    os_family == 'Debian'
  end

  def suse?
    os_family == 'Suse'
  end

  def x86_64?
    ['x86_64', 'amd64'].include?(os_architecture)
  end
end
