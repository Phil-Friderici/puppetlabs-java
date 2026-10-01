# frozen_string_literal: true

require 'json'

# Helper methods shared by the Litmus acceptance tests of the java module.
#
# The methods are available inside examples (e.g. `debian?`) and can also be
# called on the module itself (e.g. `JavaAcceptanceHelpers.debian?`).
# All values that depend on the target are resolved lazily on the target under
# test, so loading the spec files does not require a provisioned target.
module JavaAcceptanceHelpers
  # Custom facts shipped by this module.
  JAVA_FACTS = ['java_version', 'java_major_version', 'java_patch_level', 'java_default_home', 'java_libjvm_path'].freeze

  class << self
    # The `os` fact of the target does not change during a run, cache it.
    attr_accessor :cached_os_facts
  end

  module_function

  # Run a shell command on the target under test.
  def target_shell(command, opts = {})
    LitmusHelper.instance.run_shell(command, opts)
  end

  # Prepare the target for package installations (refresh stale package indexes).
  def prepare_target
    target_shell('if command -v apt-get >/dev/null 2>&1; then apt-get update -qq; fi', expect_failures: true)
  end

  # The structured `os` fact of the target.
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

  # Major version of the OpenJDK installed by `class { 'java': }`, mirrors java::params.
  def default_java_major_version
    if debian?
      case os_release_major
      when '13', '26.04' then '21'
      when '12', '24.04' then '17'
      else '11'
      end
    elsif redhat? && os_release_major.to_i >= 10
      '21'
    else
      '8'
    end
  end

  # Name of the package installed by `class { 'java': distribution => $distribution }`.
  def java_package_name(distribution = 'jdk')
    major = default_java_major_version
    if debian?
      (distribution == 'jre') ? "openjdk-#{major}-jre-headless" : "openjdk-#{major}-jdk"
    elsif suse?
      (distribution == 'jre') ? 'java-1_8_0-openjdk' : 'java-1_8_0-openjdk-devel'
    else
      base = (major == '8') ? 'java-1.8.0-openjdk' : "java-#{major}-openjdk"
      (distribution == 'jre') ? base : "#{base}-devel"
    end
  end

  # Debian architecture name as used in the OpenJDK alternative names.
  def debian_java_architecture
    { 'aarch64' => 'arm64', 'armv7l' => 'armhf' }.fetch(os_architecture, os_architecture)
  end

  # Name of the Debian java alternative managed by the module.
  def java_alternative
    "java-1.#{default_java_major_version}.0-openjdk-#{debian_java_architecture}"
  end

  # JAVA_HOME written to /etc/environment by java::config, mirrors java::params.
  def java_home
    major = default_java_major_version
    if debian?
      "/usr/lib/jvm/#{java_alternative}/"
    elsif suse?
      '/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/'
    else
      (major == '8') ? '/usr/lib/jvm/java-1.8.0/' : "/usr/lib/jvm/java-#{major}-openjdk/"
    end
  end

  # Path of the java binary the Debian alternative points to.
  def java_alternative_path
    "#{java_home}bin/java"
  end

  # Default base directory of java::adoptium and java::sap installations.
  def archive_basedir
    redhat? ? '/usr/java' : '/usr/lib/jvm'
  end

  # Regexp matching a full java version string (e.g. "1.8.0_412" or "11.0.24") of the given major version.
  def java_version_pattern(major)
    (major.to_s == '8') ? %r{\A1\.8\.0(_\d+)?\z} : %r{\A#{Regexp.escape(major.to_s)}(\.\d+)*\z}
  end

  # Version string reported by `<java_bin> -version`, e.g. "11.0.24".
  def java_binary_version(java_bin = 'java')
    target_shell("#{java_bin} -version 2>&1").stdout[%r{version "([^"]+)"}, 1]
  end

  # Version string reported by `<javac_bin> -version`, e.g. "11.0.24".
  def javac_binary_version(javac_bin = 'javac')
    target_shell("#{javac_bin} -version 2>&1").stdout[%r{javac (\S+)}, 1]
  end

  # Custom java facts as resolved on the target. Not cached, they change when java is installed.
  def java_facts
    JSON.parse(target_shell("puppet facts show #{JAVA_FACTS.join(' ')} --render-as json").stdout)
  end

  # Build a manifest declaring the java class with the given parameters.
  def java_class_manifest(params = {})
    return "class { 'java': }" if params.empty?

    width = params.keys.map { |key| key.to_s.length }.max
    lines = params.map { |key, value| "  #{key.to_s.ljust(width)} => '#{value}'," }
    "class { 'java':\n#{lines.join("\n")}\n}"
  end
end
